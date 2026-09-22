use std::{
    fs, io,
    io::Write as _,
    path::{Path, PathBuf},
};

use atomic_write_file::AtomicWriteFile;
use serde::{Deserialize, Serialize};

const HISTORY_FILE: &str = "room_history.dat";
const HISTORY_VERSION: u32 = 1;
const MAX_HISTORY: usize = 5;

#[derive(Clone, Copy, Debug, Deserialize, Eq, PartialEq, Serialize)]
#[serde(rename_all = "snake_case")]
pub(crate) enum StoredRoomRoute {
    Relay,
    Lan,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub(crate) struct RoomHistoryEntry {
    pub id: u64,
    pub join_code: String,
    pub route: StoredRoomRoute,
}

#[derive(Debug)]
pub(crate) struct RoomHistoryStore {
    path: Option<PathBuf>,
    data: StoredRoomHistory,
    warning: Option<String>,
}

#[derive(Debug, Deserialize, Serialize)]
struct StoredRoomHistory {
    version: u32,
    next_id: u64,
    restore_id: Option<u64>,
    entries: Vec<StoredRoomHistoryEntry>,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
struct StoredRoomHistoryEntry {
    id: u64,
    join_code: String,
    route: StoredRoomRoute,
}

impl Default for StoredRoomHistory {
    fn default() -> Self {
        Self {
            version: HISTORY_VERSION,
            next_id: 1,
            restore_id: None,
            entries: Vec::new(),
        }
    }
}

impl RoomHistoryStore {
    pub(crate) fn load() -> Self {
        let path = tractor_beam_core::bundle_directory().map(|root| root.join(HISTORY_FILE));
        let Some(path) = path else {
            return Self {
                path: None,
                data: StoredRoomHistory::default(),
                warning: Some("联机码历史目录不可用".to_owned()),
            };
        };
        if !path.exists() {
            return Self {
                path: Some(path),
                data: StoredRoomHistory::default(),
                warning: None,
            };
        }
        match read_history(&path) {
            Ok(data) => Self {
                path: Some(path),
                data,
                warning: None,
            },
            Err(_) => Self {
                path: Some(path),
                data: StoredRoomHistory::default(),
                warning: Some("无法读取已加密的联机码历史，本次将使用空历史".to_owned()),
            },
        }
    }

    pub(crate) fn entries(&self) -> Vec<RoomHistoryEntry> {
        self.data
            .entries
            .iter()
            .map(|entry| RoomHistoryEntry {
                id: entry.id,
                join_code: entry.join_code.clone(),
                route: entry.route,
            })
            .collect()
    }

    pub(crate) fn entry(&self, id: u64) -> Option<RoomHistoryEntry> {
        self.data
            .entries
            .iter()
            .find(|entry| entry.id == id)
            .map(|entry| RoomHistoryEntry {
                id: entry.id,
                join_code: entry.join_code.clone(),
                route: entry.route,
            })
    }

    pub(crate) fn restore_entry(&self) -> Option<RoomHistoryEntry> {
        // Relay rooms are backed by a process-independent server and can be
        // rejoined safely after this client restarts. A LAN invitation points
        // at listeners owned by the previous host process and may also require
        // an interactive endpoint choice, so it remains in history for manual
        // use but must never drive unattended startup restoration.
        self.data
            .restore_id
            .and_then(|id| self.entry(id))
            .filter(|entry| entry.route == StoredRoomRoute::Relay)
    }

    pub(crate) fn warning(&self) -> Option<&str> {
        self.warning.as_deref()
    }

    pub(crate) fn record_success(
        &mut self,
        join_code: &str,
        route: StoredRoomRoute,
    ) -> io::Result<u64> {
        let existing = self
            .data
            .entries
            .iter()
            .position(|entry| entry.join_code == join_code)
            .map(|index| self.data.entries.remove(index));
        let id = existing.as_ref().map_or_else(
            || {
                let id = self.data.next_id;
                self.data.next_id = self.data.next_id.saturating_add(1).max(1);
                id
            },
            |entry| entry.id,
        );
        self.data.entries.insert(
            0,
            StoredRoomHistoryEntry {
                id,
                join_code: join_code.to_owned(),
                route,
            },
        );
        self.data.entries.truncate(MAX_HISTORY);
        self.data.restore_id = Some(id);
        self.save()?;
        Ok(id)
    }

    pub(crate) fn clear_restore(&mut self) -> io::Result<()> {
        if self.data.restore_id.take().is_some() {
            self.save()?;
        }
        Ok(())
    }

    fn save(&self) -> io::Result<()> {
        let path = self
            .path
            .as_ref()
            .ok_or_else(|| io::Error::new(io::ErrorKind::NotFound, "history path unavailable"))?;
        let plain = serde_json::to_vec(&self.data).map_err(io::Error::other)?;
        let protected = protect(&plain)?;
        let mut file = AtomicWriteFile::open(path)?;
        file.write_all(&protected)?;
        file.commit()
    }
}

fn read_history(path: &Path) -> io::Result<StoredRoomHistory> {
    let protected = fs::read(path)?;
    let plain = unprotect(&protected)?;
    let mut data: StoredRoomHistory = serde_json::from_slice(&plain).map_err(io::Error::other)?;
    if data.version != HISTORY_VERSION {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "unsupported room history version",
        ));
    }
    data.entries
        .retain(|entry| !entry.join_code.trim().is_empty());
    data.entries.truncate(MAX_HISTORY);
    if data
        .restore_id
        .is_some_and(|id| !data.entries.iter().any(|entry| entry.id == id))
    {
        data.restore_id = None;
    }
    Ok(data)
}

#[cfg(windows)]
fn protect(input: &[u8]) -> io::Result<Vec<u8>> {
    use std::{ptr, slice};
    use windows_sys::Win32::{
        Foundation::LocalFree,
        Security::Cryptography::{CRYPT_INTEGER_BLOB, CRYPTPROTECT_UI_FORBIDDEN, CryptProtectData},
    };

    let input_len = u32::try_from(input.len())
        .map_err(|_| io::Error::new(io::ErrorKind::InvalidInput, "history is too large"))?;
    let input_blob = CRYPT_INTEGER_BLOB {
        cbData: input_len,
        pbData: input.as_ptr().cast_mut(),
    };
    let mut output_blob = CRYPT_INTEGER_BLOB {
        cbData: 0,
        pbData: ptr::null_mut(),
    };
    // SAFETY: both blobs point to valid buffers for the duration of the call; Windows allocates
    // the output buffer and documents that it must be released with LocalFree.
    let result = unsafe {
        CryptProtectData(
            &raw const input_blob,
            ptr::null(),
            ptr::null(),
            ptr::null(),
            ptr::null(),
            CRYPTPROTECT_UI_FORBIDDEN,
            &raw mut output_blob,
        )
    };
    if result == 0 {
        return Err(io::Error::last_os_error());
    }
    // SAFETY: a successful CryptProtectData call returns a valid buffer of cbData bytes.
    let output =
        unsafe { slice::from_raw_parts(output_blob.pbData, output_blob.cbData as usize).to_vec() };
    // SAFETY: the buffer was allocated by CryptProtectData and has not been freed yet.
    unsafe { LocalFree(output_blob.pbData.cast()) };
    Ok(output)
}

#[cfg(windows)]
fn unprotect(input: &[u8]) -> io::Result<Vec<u8>> {
    use std::{ptr, slice};
    use windows_sys::Win32::{
        Foundation::LocalFree,
        Security::Cryptography::{
            CRYPT_INTEGER_BLOB, CRYPTPROTECT_UI_FORBIDDEN, CryptUnprotectData,
        },
    };

    let input_len = u32::try_from(input.len())
        .map_err(|_| io::Error::new(io::ErrorKind::InvalidInput, "history is too large"))?;
    let input_blob = CRYPT_INTEGER_BLOB {
        cbData: input_len,
        pbData: input.as_ptr().cast_mut(),
    };
    let mut output_blob = CRYPT_INTEGER_BLOB {
        cbData: 0,
        pbData: ptr::null_mut(),
    };
    // SAFETY: input is valid for the call; optional pointers are null; Windows owns output.
    let result = unsafe {
        CryptUnprotectData(
            &raw const input_blob,
            ptr::null_mut(),
            ptr::null(),
            ptr::null(),
            ptr::null(),
            CRYPTPROTECT_UI_FORBIDDEN,
            &raw mut output_blob,
        )
    };
    if result == 0 {
        return Err(io::Error::last_os_error());
    }
    // SAFETY: a successful CryptUnprotectData call returns a valid buffer of cbData bytes.
    let output =
        unsafe { slice::from_raw_parts(output_blob.pbData, output_blob.cbData as usize).to_vec() };
    // SAFETY: the buffer was allocated by CryptUnprotectData and has not been freed yet.
    unsafe { LocalFree(output_blob.pbData.cast()) };
    Ok(output)
}

#[cfg(not(windows))]
fn protect(_: &[u8]) -> io::Result<Vec<u8>> {
    Err(io::Error::new(
        io::ErrorKind::Unsupported,
        "encrypted room history is only available on Windows",
    ))
}

#[cfg(not(windows))]
fn unprotect(_: &[u8]) -> io::Result<Vec<u8>> {
    Err(io::Error::new(
        io::ErrorKind::Unsupported,
        "encrypted room history is only available on Windows",
    ))
}

#[cfg(all(test, windows))]
mod tests {
    use super::*;

    #[test]
    fn encrypted_history_round_trips_and_keeps_five_unique_codes() {
        let directory = tempfile::tempdir().unwrap();
        let path = directory.path().join(HISTORY_FILE);
        let mut store = RoomHistoryStore {
            path: Some(path.clone()),
            data: StoredRoomHistory::default(),
            warning: None,
        };
        for index in 0..7 {
            store
                .record_success(&format!("Bcode-{index}B"), StoredRoomRoute::Relay)
                .unwrap();
        }
        store
            .record_success("Bcode-4B", StoredRoomRoute::Lan)
            .unwrap();

        let encrypted = fs::read(&path).unwrap();
        assert!(!String::from_utf8_lossy(&encrypted).contains("Bcode-4B"));
        let data = read_history(&path).unwrap();
        assert_eq!(data.entries.len(), 5);
        assert_eq!(data.entries[0].join_code, "Bcode-4B");
        assert_eq!(data.entries[0].route, StoredRoomRoute::Lan);
        assert_eq!(data.restore_id, Some(data.entries[0].id));
        assert!(store.restore_entry().is_none());

        store
            .record_success("Brelay-restoreB", StoredRoomRoute::Relay)
            .unwrap();
        assert_eq!(
            store.restore_entry().map(|entry| entry.join_code),
            Some("Brelay-restoreB".to_owned())
        );
    }
}
