use std::time::Duration;

use semver::Version;
use serde::Deserialize;

const GITHUB_API_VERSION: &str = "2026-03-10";
const RESPONSE_LIMIT_BYTES: u64 = 64 * 1024;
const UPDATE_CHECK_TIMEOUT: Duration = Duration::from_secs(5);

pub(crate) type UpdateCheck = Box<dyn FnOnce() -> Result<Option<AvailableUpdate>, String> + Send>;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct ReleaseChannel {
    pub latest_release_api: &'static str,
    pub release_url_prefix: &'static str,
}

pub const UPSTREAM_CHANNEL: ReleaseChannel = ReleaseChannel {
    latest_release_api: "https://api.github.com/repos/mcthesw/TractorBeam/releases/latest",
    release_url_prefix: "https://github.com/mcthesw/TractorBeam/releases/",
};

pub const FLUTTER_CHANNEL: ReleaseChannel = ReleaseChannel {
    latest_release_api: "https://api.github.com/repos/tianguantg/TractorBeam/releases/latest",
    release_url_prefix: "https://github.com/tianguantg/TractorBeam/releases/",
};

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct AvailableUpdate {
    pub version: String,
    pub url: String,
}

#[derive(Debug, Deserialize)]
pub struct GitHubRelease {
    pub tag_name: String,
    pub html_url: String,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ParsedReleaseVersion {
    pub base: Version,
    pub fork_revision: Option<u64>,
}

impl ParsedReleaseVersion {
    pub fn parse(raw: &str) -> Result<Self, String> {
        let text = raw.trim();
        let text = text
            .strip_prefix('v')
            .or_else(|| text.strip_prefix('V'))
            .unwrap_or(text);
        if text == "dev" {
            return Err("Version \"dev\" is not a release version".to_owned());
        }
        if let Some((base_str, fork_str)) = text.split_once("-tb.") {
            let base = Version::parse(base_str)
                .map_err(|error| format!("Base version {base_str:?} is invalid: {error}"))?;
            let fork_revision = fork_str
                .parse::<u64>()
                .map_err(|error| format!("Fork revision {fork_str:?} is invalid: {error}"))?;
            Ok(Self {
                base,
                fork_revision: Some(fork_revision),
            })
        } else {
            let base = Version::parse(text)
                .map_err(|error| format!("Version {text:?} is invalid: {error}"))?;
            Ok(Self {
                base,
                fork_revision: None,
            })
        }
    }
}

impl Ord for ParsedReleaseVersion {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        match self.base.cmp(&other.base) {
            std::cmp::Ordering::Equal => match (self.fork_revision, other.fork_revision) {
                (Some(a), Some(b)) => a.cmp(&b),
                (Some(_), None) => std::cmp::Ordering::Greater,
                (None, Some(_)) => std::cmp::Ordering::Less,
                (None, None) => std::cmp::Ordering::Equal,
            },
            ord => ord,
        }
    }
}

impl PartialOrd for ParsedReleaseVersion {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        Some(self.cmp(other))
    }
}

pub fn check_for_update_with_channel(
    current_version: &str,
    channel: ReleaseChannel,
) -> Result<Option<AvailableUpdate>, String> {
    if current_version.trim() == "dev" {
        return Ok(None);
    }
    let config = ureq::Agent::config_builder()
        .timeout_global(Some(UPDATE_CHECK_TIMEOUT))
        .build();
    let agent: ureq::Agent = config.into();
    let user_agent = format!("Tractor-Beam/{current_version}");
    let mut response = agent
        .get(channel.latest_release_api)
        .header("Accept", "application/vnd.github+json")
        .header("X-GitHub-Api-Version", GITHUB_API_VERSION)
        .header("User-Agent", user_agent)
        .call()
        .map_err(|error| format!("GitHub latest release request failed: {error}"))?;
    let release = response
        .body_mut()
        .with_config()
        .limit(RESPONSE_LIMIT_BYTES)
        .read_json::<GitHubRelease>()
        .map_err(|error| format!("GitHub latest release response was invalid: {error}"))?;

    available_update_with_channel(current_version, &release, channel)
}

pub(crate) fn check_for_update(current_version: &str) -> Result<Option<AvailableUpdate>, String> {
    check_for_update_with_channel(current_version, UPSTREAM_CHANNEL)
}

pub(crate) fn spawn_check(
    update_check: Option<UpdateCheck>,
    on_available: impl FnOnce(AvailableUpdate) + Send + 'static,
) {
    let Some(update_check) = update_check else {
        return;
    };
    if let Err(error) = std::thread::Builder::new()
        .name("tractor-beam-update-check".to_owned())
        .spawn(move || match update_check() {
            Ok(Some(update)) => {
                tracing::info!(available_version = %update.version, "New Tractor Beam release available");
                on_available(update);
            }
            Ok(None) => tracing::debug!("Tractor Beam is up to date"),
            Err(error) => tracing::warn!(error = %error, "Update check failed"),
        })
    {
        tracing::warn!(error = %error, "Could not start update check worker");
    }
}

pub fn available_update_with_channel(
    current_version: &str,
    release: &GitHubRelease,
    channel: ReleaseChannel,
) -> Result<Option<AvailableUpdate>, String> {
    let current = ParsedReleaseVersion::parse(current_version)
        .map_err(|error| format!("Current version {current_version:?} is invalid: {error}"))?;
    let tag = release.tag_name.trim();
    let latest = ParsedReleaseVersion::parse(tag).map_err(|error| {
        format!(
            "Release tag {:?} is not a valid version: {error}",
            release.tag_name
        )
    })?;
    if latest <= current {
        return Ok(None);
    }
    if !release.html_url.starts_with(channel.release_url_prefix) {
        return Err(format!(
            "Release URL {:?} is outside repository prefix {:?}",
            release.html_url, channel.release_url_prefix
        ));
    }
    let version_text = tag
        .strip_prefix('v')
        .or_else(|| tag.strip_prefix('V'))
        .unwrap_or(tag);
    Ok(Some(AvailableUpdate {
        version: version_text.to_owned(),
        url: release.html_url.clone(),
    }))
}

#[allow(dead_code)]
pub(crate) fn available_update(
    current_version: &str,
    release: &GitHubRelease,
) -> Result<Option<AvailableUpdate>, String> {
    available_update_with_channel(current_version, release, UPSTREAM_CHANNEL)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn upstream_release(tag_name: &str) -> GitHubRelease {
        GitHubRelease {
            tag_name: tag_name.to_owned(),
            html_url: format!("{}tag/{tag_name}", UPSTREAM_CHANNEL.release_url_prefix),
        }
    }

    fn flutter_release(tag_name: &str) -> GitHubRelease {
        GitHubRelease {
            tag_name: tag_name.to_owned(),
            html_url: format!("{}tag/{tag_name}", FLUTTER_CHANNEL.release_url_prefix),
        }
    }

    #[test]
    fn newer_semver_release_is_available() {
        let update = available_update("0.5.1", &upstream_release("v0.6.0"))
            .unwrap()
            .unwrap();

        assert_eq!(update.version, "0.6.0");
        assert_eq!(
            update.url,
            "https://github.com/mcthesw/TractorBeam/releases/tag/v0.6.0"
        );
    }

    #[test]
    fn equal_or_older_release_is_not_available() {
        assert_eq!(
            available_update("0.5.1", &upstream_release("v0.5.1")).unwrap(),
            None
        );
        assert_eq!(
            available_update("0.5.1", &upstream_release("v0.5.0")).unwrap(),
            None
        );
    }

    #[test]
    fn stable_release_updates_a_prerelease_build() {
        let update = available_update("0.6.0-beta.1", &upstream_release("0.6.0"))
            .unwrap()
            .unwrap();

        assert_eq!(update.version, "0.6.0");
    }

    #[test]
    fn invalid_versions_and_unexpected_urls_are_rejected() {
        assert!(available_update("dev", &upstream_release("v0.6.0")).is_err());
        assert!(available_update("0.5.1", &upstream_release("latest")).is_err());

        let mut unexpected = upstream_release("v0.6.0");
        unexpected.html_url = "https://example.com/v0.6.0".to_owned();
        assert!(available_update("0.5.1", &unexpected).is_err());
    }

    #[test]
    fn fork_revision_comparison_recognizes_newer_tb_revision() {
        let update = available_update_with_channel(
            "0.5.2-tb.1",
            &flutter_release("v0.5.2-tb.2"),
            FLUTTER_CHANNEL,
        )
        .unwrap()
        .unwrap();

        assert_eq!(update.version, "0.5.2-tb.2");
        assert_eq!(
            update.url,
            "https://github.com/tianguantg/TractorBeam/releases/tag/v0.5.2-tb.2"
        );

        // Same revision -> no update
        assert_eq!(
            available_update_with_channel(
                "0.5.2-tb.1",
                &flutter_release("v0.5.2-tb.1"),
                FLUTTER_CHANNEL,
            )
            .unwrap(),
            None
        );

        // Older revision -> no update
        assert_eq!(
            available_update_with_channel(
                "0.5.2-tb.2",
                &flutter_release("v0.5.2-tb.1"),
                FLUTTER_CHANNEL,
            )
            .unwrap(),
            None
        );

        // Base version bump -> update
        let bump = available_update_with_channel(
            "0.5.2-tb.9",
            &flutter_release("v0.5.3-tb.1"),
            FLUTTER_CHANNEL,
        )
        .unwrap()
        .unwrap();
        assert_eq!(bump.version, "0.5.3-tb.1");

        // Upstream release without tb tag should not downgrade a -tb.1 release
        assert_eq!(
            available_update_with_channel(
                "0.5.2-tb.1",
                &flutter_release("v0.5.2"),
                FLUTTER_CHANNEL,
            )
            .unwrap(),
            None
        );

        // Base release without tb tag is upgraded by -tb.1
        let tb_upgrade = available_update_with_channel(
            "0.5.2",
            &flutter_release("v0.5.2-tb.1"),
            FLUTTER_CHANNEL,
        )
        .unwrap()
        .unwrap();
        assert_eq!(tb_upgrade.version, "0.5.2-tb.1");
    }

    #[test]
    fn flutter_channel_rejects_mismatched_repository_prefix() {
        let mismatched = GitHubRelease {
            tag_name: "v0.5.2-tb.2".to_owned(),
            html_url: "https://github.com/mcthesw/TractorBeam/releases/tag/v0.5.2-tb.2".to_owned(),
        };
        assert!(available_update_with_channel("0.5.2-tb.1", &mismatched, FLUTTER_CHANNEL).is_err());
    }

    #[test]
    fn dev_build_skips_automatic_update_check() {
        // dev build returns Ok(None) in check_for_update_with_channel without making network request
        assert_eq!(
            check_for_update_with_channel("dev", FLUTTER_CHANNEL).unwrap(),
            None
        );
    }
}
