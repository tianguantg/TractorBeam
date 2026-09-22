use super::*;

#[test]
fn parses_relay_presets_and_defaults() {
    let raw = r#"
default_transport = "tcp"
default_mode = "pure"
selected_relay = "current"
[session_health]
enabled = true
runtime_rtt_enabled = false
snapshot_interval_seconds = 10
[[relays]]
id = "current"
name = "Current test relay"
host = "relay.example.test"
port = 25910
udp = true
tcp = true
default_transport = "tcp"
"#;
    let config: ClientConfig = toml::from_str::<RawClientConfig>(raw)
        .unwrap()
        .try_into()
        .unwrap();
    assert_eq!(config.default_transport, Some(TransportChoice::Tcp));
    assert_eq!(config.default_mode, SessionMode::Pure);
    assert!(config.session_health.enabled);
    assert!(!config.session_health.runtime_rtt_enabled);
    assert_eq!(config.session_health.snapshot_interval_seconds, 10);
    assert_eq!(config.selected_relay_index(), Some(0));
    assert_eq!(
        config.relays[0].preferred_transport(TransportChoice::Udp),
        TransportChoice::Tcp
    );
}
#[test]
fn parses_ipv6_relay_preset() {
    let raw = r#"
[[relays]]
id = "ipv6"
name = "IPv6 relay"
host = "[2001:db8::10]"
port = 25910
"#;

    let config: ClientConfig = toml::from_str::<RawClientConfig>(raw)
        .unwrap()
        .try_into()
        .unwrap();
    assert_eq!(config.relays[0].endpoint.host, "2001:db8::10");
}

#[test]
fn rejects_invalid_session_health_interval() {
    let raw = "[session_health]\nenabled = true\nsnapshot_interval_seconds = 0\n";
    let error =
        ClientConfig::try_from(toml::from_str::<RawClientConfig>(raw).unwrap()).unwrap_err();
    assert!(matches!(error, ClientConfigError::InvalidSessionHealth(_)));
}

#[test]
fn defaults_transport_to_none_when_omitted() {
    let config: ClientConfig = toml::from_str::<RawClientConfig>("")
        .unwrap()
        .try_into()
        .unwrap();
    assert_eq!(config.default_transport, None);
}

#[test]
fn save_selection_writes_keys_without_clobbering_others() {
    let temp = tempfile::tempdir().unwrap();
    let dir = temp.path();
    let config_path = dir.join(CLIENT_CONFIG_FILE);
    std::fs::write(
        &config_path,
        "# keep this comment\ndefault_transport = \"tcp\"\nroom = \"legacy-room-value\"\n[[relays]]\nid = \"r1\"\nname = \"Relay 1\"\nhost = \"relay.example.test\"\nport = 25910\n",
    )
    .unwrap();
    save_client_config_selection_to(
        &config_path,
        &ClientConfigSelection {
            selected_relay: Some("r1".to_owned()),
            selected_steam_id64: Some("76561198000000001".to_owned()),
        },
    )
    .unwrap();
    let content = std::fs::read_to_string(&config_path).unwrap();
    assert!(content.contains("selected_relay = \"r1\""));
    assert!(content.contains("selected_steam_id64 = \"76561198000000001\""));
    assert!(content.contains("# keep this comment"));
    assert!(content.contains("room = \"legacy-room-value\""));
    assert!(content.contains("[[relays]]"));
}

#[test]
fn save_selection_reports_the_main_config_write_error() {
    let temp = tempfile::tempdir().unwrap();
    let dir = temp.path().join("config.toml");
    std::fs::create_dir_all(&dir).unwrap();

    let error = save_client_config_selection_to(&dir, &ClientConfigSelection::default())
        .expect_err("a directory cannot be replaced as config.toml");

    assert!(matches!(error, ClientConfigError::Io { .. }));
}

#[test]
fn relay_catalog_adds_and_selects_a_numeric_record_without_clobbering_config() {
    let temp = tempfile::tempdir().unwrap();
    let config_path = temp.path().join(CLIENT_CONFIG_FILE);
    std::fs::write(
        &config_path,
        "# keep this comment\ncustom_key = \"keep\"\n[[relays]]\nid = \"legacy\"\nname = \"Legacy Relay\"\nhost = \"legacy.example.test\"\nport = 25910\n[[relays]]\nid = \"4\"\nname = \"Relay 4\"\nhost = \"four.example.test\"\nport = 25910\n",
    )
    .unwrap();

    let loaded = save_client_relay_catalog_to(
        &config_path,
        &RelayCatalogChange::Add(relay_input("New Relay", "new.example.test")),
    )
    .unwrap();

    assert_eq!(loaded.config.selected_relay.as_deref(), Some("5"));
    assert_eq!(loaded.config.relays.last().unwrap().id, "5");
    let content = std::fs::read_to_string(&config_path).unwrap();
    assert!(content.contains("# keep this comment"));
    assert!(content.contains("custom_key = \"keep\""));
    assert!(content.contains("next_relay_id = 6"));
}

#[test]
fn relay_catalog_updates_in_place_and_preserves_the_record_id() {
    let temp = tempfile::tempdir().unwrap();
    let config_path = temp.path().join(CLIENT_CONFIG_FILE);
    std::fs::write(
        &config_path,
        "selected_relay = \"relay-a\"\n[[relays]]\nid = \" relay-a \"\n# keep relay note\nname = \"Old\"\nhost = \"old.example.test\"\nport = 25910\n",
    )
    .unwrap();
    let mut input = relay_input("Updated", "new.example.test");
    input.supports_udp = false;

    let loaded = save_client_relay_catalog_to(
        &config_path,
        &RelayCatalogChange::Update {
            id: "relay-a".to_owned(),
            relay: input,
        },
    )
    .unwrap();

    assert_eq!(loaded.config.selected_relay.as_deref(), Some("relay-a"));
    assert_eq!(loaded.config.relays[0].id, "relay-a");
    assert_eq!(loaded.config.relays[0].name, "Updated");
    assert!(!loaded.config.relays[0].supports_udp);
    let content = std::fs::read_to_string(&config_path).unwrap();
    assert!(content.contains("# keep relay note"));
    assert!(content.contains("id = \" relay-a \""));
}

#[test]
fn relay_catalog_deletes_an_existing_id_with_surrounding_whitespace() {
    let temp = tempfile::tempdir().unwrap();
    let config_path = temp.path().join(CLIENT_CONFIG_FILE);
    std::fs::write(
        &config_path,
        "selected_relay = \"relay-a\"\n[[relays]]\nid = \" relay-a \"\nname = \"Relay A\"\nhost = \"relay.example.test\"\nport = 25910\n",
    )
    .unwrap();

    let loaded = save_client_relay_catalog_to(
        &config_path,
        &RelayCatalogChange::Delete {
            id: "relay-a".to_owned(),
        },
    )
    .unwrap();

    assert!(loaded.config.relays.is_empty());
    assert!(loaded.config.selected_relay.is_none());
}

#[test]
fn relay_catalog_delete_clears_selection_and_does_not_reuse_its_record_number() {
    let temp = tempfile::tempdir().unwrap();
    let config_path = temp.path().join(CLIENT_CONFIG_FILE);
    std::fs::write(
        &config_path,
        "selected_relay = \"8\"\n[[relays]]\nid = \"8\"\nname = \"Relay 8\"\nhost = \"eight.example.test\"\nport = 25910\n",
    )
    .unwrap();

    let deleted = save_client_relay_catalog_to(
        &config_path,
        &RelayCatalogChange::Delete { id: "8".to_owned() },
    )
    .unwrap();
    assert!(deleted.config.selected_relay.is_none());
    assert!(deleted.config.relays.is_empty());

    let added = save_client_relay_catalog_to(
        &config_path,
        &RelayCatalogChange::Add(relay_input("Relay 9", "nine.example.test")),
    )
    .unwrap();
    assert_eq!(added.config.selected_relay.as_deref(), Some("9"));
    assert_eq!(added.config.relays[0].id, "9");
}

#[test]
fn relay_catalog_rejects_an_unsupported_default_transport_without_writing() {
    let temp = tempfile::tempdir().unwrap();
    let config_path = temp.path().join(CLIENT_CONFIG_FILE);
    std::fs::write(&config_path, "# unchanged\n").unwrap();
    let mut input = relay_input("Broken", "broken.example.test");
    input.supports_tcp = false;

    let error =
        save_client_relay_catalog_to(&config_path, &RelayCatalogChange::Add(input)).unwrap_err();

    assert!(matches!(error, ClientConfigError::InvalidRelay(_)));
    assert_eq!(
        std::fs::read_to_string(config_path).unwrap(),
        "# unchanged\n"
    );
}

#[test]
fn preferences_are_saved_without_discarding_other_config() {
    let temp = tempfile::tempdir().unwrap();
    let config_path = temp.path().join(CLIENT_CONFIG_FILE);
    std::fs::write(
        &config_path,
        "# retained\nselected_steam_id64 = \"76561198000000000\"\n",
    )
    .unwrap();

    let saved = save_client_config_preferences_to(
        &config_path,
        ClientConfigPreferences {
            default_transport: Some(TransportChoice::Udp),
            default_mode: SessionMode::Fallback,
            session_health_enabled: true,
        },
    )
    .unwrap();

    assert_eq!(saved.config.default_transport, Some(TransportChoice::Udp));
    assert_eq!(saved.config.default_mode, SessionMode::Fallback);
    assert!(saved.config.session_health.enabled);
    assert_eq!(
        saved.config.selected_steam_id64.as_deref(),
        Some("76561198000000000")
    );
    assert!(
        std::fs::read_to_string(&config_path)
            .unwrap()
            .contains("# retained")
    );

    let saved_none = save_client_config_preferences_to(
        &config_path,
        ClientConfigPreferences {
            default_transport: None,
            default_mode: SessionMode::Pure,
            session_health_enabled: true,
        },
    )
    .unwrap();

    assert_eq!(saved_none.config.default_transport, None);
    assert!(
        !std::fs::read_to_string(&config_path)
            .unwrap()
            .contains("default_transport")
    );
}

#[test]
fn preferences_reject_a_non_table_health_section_without_writing() {
    let temp = tempfile::tempdir().unwrap();
    let config_path = temp.path().join(CLIENT_CONFIG_FILE);
    let original = "session_health = \"invalid\"\n";
    std::fs::write(&config_path, original).unwrap();

    let error = save_client_config_preferences_to(
        &config_path,
        ClientConfigPreferences {
            default_transport: Some(TransportChoice::Tcp),
            default_mode: SessionMode::Pure,
            session_health_enabled: true,
        },
    )
    .unwrap_err();

    assert!(matches!(error, ClientConfigError::InvalidDocument(_)));
    assert_eq!(std::fs::read_to_string(config_path).unwrap(), original);
}

#[test]
fn manual_steam_account_is_persisted_selected_and_updated_in_place() {
    let temp = tempfile::tempdir().unwrap();
    let config_path = temp.path().join(CLIENT_CONFIG_FILE);
    std::fs::write(&config_path, "# retained\ncustom_key = \"keep\"\n").unwrap();

    let first = save_client_manual_steam_account_to(
        &config_path,
        ManualSteamAccount {
            steam_id64: " 76561198000000000 ".to_owned(),
            display_name: " First Name ".to_owned(),
        },
    )
    .unwrap();
    assert_eq!(
        first.config.selected_steam_id64.as_deref(),
        Some("76561198000000000")
    );
    assert_eq!(first.config.manual_steam_accounts.len(), 1);
    assert_eq!(
        first.config.manual_steam_accounts[0].display_name,
        "First Name"
    );

    let updated = save_client_manual_steam_account_to(
        &config_path,
        ManualSteamAccount {
            steam_id64: "76561198000000000".to_owned(),
            display_name: "Updated Name".to_owned(),
        },
    )
    .unwrap();
    assert_eq!(updated.config.manual_steam_accounts.len(), 1);
    assert_eq!(
        updated.config.manual_steam_accounts[0].display_name,
        "Updated Name"
    );
    assert!(
        std::fs::read_to_string(config_path)
            .unwrap()
            .contains("# retained")
    );
}

#[test]
fn invalid_manual_steam_account_does_not_modify_config() {
    let temp = tempfile::tempdir().unwrap();
    let config_path = temp.path().join(CLIENT_CONFIG_FILE);
    let original = "# unchanged\n";
    std::fs::write(&config_path, original).unwrap();

    let error = save_client_manual_steam_account_to(
        &config_path,
        ManualSteamAccount {
            steam_id64: "not-an-id".to_owned(),
            display_name: "Player".to_owned(),
        },
    )
    .unwrap_err();
    assert!(matches!(error, ClientConfigError::InvalidSteamAccount(_)));
    assert_eq!(std::fs::read_to_string(&config_path).unwrap(), original);

    // Test zero SteamID is rejected
    let error_zero = save_client_manual_steam_account_to(
        &config_path,
        ManualSteamAccount {
            steam_id64: "0".to_owned(),
            display_name: "Player".to_owned(),
        },
    )
    .unwrap_err();
    assert!(matches!(
        error_zero,
        ClientConfigError::InvalidSteamAccount(_)
    ));

    // Test short SteamID (< 17 digits) is rejected
    let error_short = save_client_manual_steam_account_to(
        &config_path,
        ManualSteamAccount {
            steam_id64: "1234567890".to_owned(),
            display_name: "Player".to_owned(),
        },
    )
    .unwrap_err();
    assert!(matches!(
        error_short,
        ClientConfigError::InvalidSteamAccount(_)
    ));

    // Test empty display name is rejected
    let error_empty_name = save_client_manual_steam_account_to(
        &config_path,
        ManualSteamAccount {
            steam_id64: "76561198000000000".to_owned(),
            display_name: "   ".to_owned(),
        },
    )
    .unwrap_err();
    assert!(matches!(
        error_empty_name,
        ClientConfigError::InvalidSteamAccount(_)
    ));
}

#[test]
fn delete_manual_steam_account_removes_entry_and_resets_selected() {
    let temp = tempfile::tempdir().unwrap();
    let config_path = temp.path().join(CLIENT_CONFIG_FILE);
    std::fs::write(&config_path, "# initial\n").unwrap();

    let loaded = save_client_manual_steam_account_to(
        &config_path,
        ManualSteamAccount {
            steam_id64: "76561198000000001".to_owned(),
            display_name: "Player One".to_owned(),
        },
    )
    .unwrap();
    assert_eq!(loaded.config.manual_steam_accounts.len(), 1);
    assert_eq!(
        loaded.config.selected_steam_id64.as_deref(),
        Some("76561198000000001")
    );

    let after_delete =
        delete_client_manual_steam_account_to(&config_path, "76561198000000001").unwrap();
    assert_eq!(after_delete.config.manual_steam_accounts.len(), 0);
    assert_eq!(after_delete.config.selected_steam_id64, None);

    // Deleting non-existent account returns error
    let err = delete_client_manual_steam_account_to(&config_path, "76561198000000001").unwrap_err();
    assert!(matches!(err, ClientConfigError::InvalidSteamAccount(_)));
}

fn relay_input(name: &str, host: &str) -> RelayProfileInput {
    RelayProfileInput {
        name: name.to_owned(),
        endpoint: RelayEndpoint::new(host, 25910),
        supports_udp: true,
        supports_tcp: true,
        default_transport: TransportChoice::Tcp,
    }
}

#[test]
fn legacy_invalid_steam_accounts_and_dangling_selected_relay_are_resiliently_handled() {
    let temp = tempfile::tempdir().unwrap();
    let config_path = temp.path().join(CLIENT_CONFIG_FILE);
    let contents = r#"
default_transport = "udp"
default_mode = "fallback"
selected_relay = "unknown-relay-id"
selected_steam_id64 = "invalid-short-id"

[session_health]
enabled = false

[[manual_steam_accounts]]
steam_id64 = "76561198000000001"
display_name = "Valid Account"

[[manual_steam_accounts]]
steam_id64 = "765611980"
display_name = "Short ID"

[[manual_steam_accounts]]
steam_id64 = "76561198000000002"
display_name = "   "

[[manual_steam_accounts]]
steam_id64 = "76561198000000001"
display_name = "Duplicate Account"
"#;
    std::fs::write(&config_path, contents).unwrap();

    let loaded = load_config_file(&config_path).expect("resilient parsing should succeed");
    assert_eq!(loaded.selected_relay, None);
    assert_eq!(loaded.selected_steam_id64, None);
    assert_eq!(loaded.manual_steam_accounts.len(), 1);
    assert_eq!(
        loaded.manual_steam_accounts[0].steam_id64,
        "76561198000000001"
    );
    assert_eq!(
        loaded.manual_steam_accounts[0].display_name,
        "Valid Account"
    );

    // Saving preferences on such a document must succeed without error
    let preferences = ClientConfigPreferences {
        default_transport: Some(TransportChoice::Tcp),
        default_mode: SessionMode::Pure,
        session_health_enabled: true,
    };
    let saved = save_client_config_preferences_to(&config_path, preferences)
        .expect("saving preferences should succeed");
    assert_eq!(saved.config.default_transport, Some(TransportChoice::Tcp));
    assert_eq!(saved.config.default_mode, SessionMode::Pure);
    assert!(saved.config.session_health.enabled);
    assert_eq!(saved.config.manual_steam_accounts.len(), 1);
}
