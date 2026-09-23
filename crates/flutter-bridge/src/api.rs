use std::{
    net::SocketAddr,
    sync::{
        Arc, Mutex, OnceLock,
        atomic::{AtomicU64, Ordering},
        mpsc::{self, SyncSender, TrySendError},
    },
    thread,
    time::{Duration, Instant},
};

use crate::frb_generated::StreamSink;
use crate::room_history::{RoomHistoryStore, StoredRoomRoute};
use tractor_beam_application::{
    check_for_update_with_channel, ApplicationEvent, ApplicationHandle, ApplicationOperation,
    ApplicationSnapshot, BootstrapState, FLUTTER_CHANNEL,
};
use tractor_beam_core::{
    ClientConfigPreferences, ClientConfigSelection, ExternalRelayConfig, HookStartupPhase,
    InputDelayError, JoinCode, LanAdapter, LanDirectConfig, LanJoinCode, LightPingReport,
    LightPingTarget, LogLevel, ManualSteamAccount, RelayCatalogChange, RelayEndpoint,
    RelayJoinCode, RelayProfileInput, SessionConfig, SessionCredential, SessionMode,
    SessionRouteConfig, SessionStatus, TransportChoice, bundle_config_path,
    delete_client_manual_steam_account_to, save_client_manual_steam_account_to,
};

static APPLICATION: OnceLock<Arc<BridgeRuntime>> = OnceLock::new();
const DEFAULT_FLUTTER_RELEASE_VERSION: &str = "0.5.2-tb.1";

fn flutter_release_version() -> &'static str {
    option_env!("TB_RELEASE_VERSION").unwrap_or(DEFAULT_FLUTTER_RELEASE_VERSION)
}

const LAUNCH_TIMEOUT: Duration = Duration::from_mins(2);
const LIGHTWEIGHT_UPDATE_INTERVAL: Duration = Duration::from_millis(250);
const BACKGROUND_UPDATE_INTERVAL: Duration = Duration::from_secs(1);

#[flutter_rust_bridge::frb(ignore)]
struct BridgeRuntime {
    application: Mutex<ApplicationHandle>,
    state: Mutex<BridgeState>,
    history: Mutex<RoomHistoryStore>,
    sinks: Mutex<Vec<StreamSink<AppUpdate>>>,
    wake_tx: SyncSender<()>,
    revision: AtomicU64,
}

#[derive(Clone, Debug, Eq, PartialEq)]
enum PendingRelayOperation {
    Add,
    Update,
    Delete { relay_name: String },
}

#[flutter_rust_bridge::frb(ignore)]
struct BridgeState {
    snapshot_profile: SnapshotProfileDto,
    initialized_from_config: bool,
    selected_relay_id: Option<String>,
    selected_steam_id64: Option<String>,
    manual_steam_accounts: Vec<ManualSteamAccount>,
    mode: Option<SessionMode>,
    transport: TransportSelection,
    room: Option<RoomSecret>,
    pending_room: Option<RoomSecret>,
    room_status: RoomStatusDto,
    room_generation: u64,
    lan_adapters: Vec<LanAdapter>,
    pending_lan: Option<PendingLanJoin>,
    pending_relay_op: Option<PendingRelayOperation>,
    launch_generation: u64,
    launch_pending: bool,
    launch_cancel_requested: bool,
    launch_cancelled: bool,
    launch_error: Option<String>,
    launch_started_at: Option<Instant>,
    update_status: UpdateStatusDto,
    available_update: Option<AvailableUpdateDto>,
    update_error: Option<String>,
}

impl Default for BridgeState {
    fn default() -> Self {
        Self {
            snapshot_profile: SnapshotProfileDto::Full,
            initialized_from_config: false,
            selected_relay_id: None,
            selected_steam_id64: None,
            manual_steam_accounts: Vec::new(),
            mode: None,
            transport: TransportSelection::default(),
            room: None,
            pending_room: None,
            room_status: RoomStatusDto::Idle,
            room_generation: 0,
            lan_adapters: Vec::new(),
            pending_lan: None,
            pending_relay_op: None,
            launch_generation: 0,
            launch_pending: false,
            launch_cancel_requested: false,
            launch_cancelled: false,
            launch_error: None,
            launch_started_at: None,
            update_status: UpdateStatusDto::Idle,
            available_update: None,
            update_error: None,
        }
    }
}

#[flutter_rust_bridge::frb(ignore)]
enum RoomSecret {
    Relay {
        route: ExternalRelayConfig,
        join_code: String,
    },
    Lan {
        credential: SessionCredential,
        join_code: String,
    },
}

#[flutter_rust_bridge::frb(ignore)]
struct PendingLanJoin {
    invitation: LanJoinCode,
    endpoints: Vec<SocketAddr>,
    join_code: String,
}

#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub enum TransportSelection {
    RelayDefault,
    Udp,
    #[default]
    Tcp,
    Unknown,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum SessionModeDto {
    Official,
    Fallback,
    Pure,
    Unknown,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum BootstrapStateDto {
    Initializing,
    Ready,
    Failed,
    Unknown,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum ShutdownStateDto {
    Running,
    ShuttingDown,
    Complete,
    Unknown,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum SessionStatusDto {
    Idle,
    Running,
    Unknown,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum RoomRouteDto {
    Relay,
    Lan,
    Unknown,
}

#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub enum RoomStatusDto {
    #[default]
    Idle,
    Creating,
    Joining,
    Active,
    Leaving,
    Failed,
    Unknown,
}

#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub enum LaunchStatusDto {
    #[default]
    Idle,
    Starting,
    WaitingForGame,
    Injecting,
    WaitingForHook,
    Cancelling,
    Ready,
    Failed,
    Cancelled,
    Unknown,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum LogLevelDto {
    Trace,
    Debug,
    Info,
    Warn,
    Error,
    Unknown,
}

#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub enum SnapshotProfileDto {
    #[default]
    Full,
    Lightweight,
    Background,
    Unknown,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
struct CriticalUpdateState {
    profile: SnapshotProfileDto,
    session: SessionStatus,
    shutdown_complete: bool,
    launch: LaunchStatusDto,
    room: RoomStatusDto,
    update: UpdateStatusDto,
}

#[derive(Clone, Debug)]
pub struct CommandReceipt {
    pub accepted: bool,
    pub rejection: Option<CommandRejection>,
}

#[derive(Clone, Debug)]
pub struct CommandRejection {
    pub code: String,
    pub display_text: String,
    pub message: LocalizedMessageDto,
}

#[derive(Clone, Debug)]
pub struct LocalizedMessageDto {
    pub key: String,
    pub args: Vec<MessageArgDto>,
    pub fallback_zh: String,
}

#[derive(Clone, Debug)]
pub struct MessageArgDto {
    pub name: String,
    pub value: String,
}

#[derive(Clone, Debug)]
pub struct AppUpdate {
    pub revision: u64,
    pub snapshot: AppSnapshot,
    pub events: Vec<AppEvent>,
}

#[derive(Clone, Debug)]
pub struct AppEvent {
    pub code: String,
    pub success: bool,
    pub display_text: String,
    pub value: Option<String>,
    pub message: LocalizedMessageDto,
}

#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub enum UpdateStatusDto {
    #[default]
    Idle,
    Checking,
    UpToDate,
    Available,
    Failed,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct AvailableUpdateDto {
    pub version: String,
    pub url: String,
}

#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct UpdateSnapshotDto {
    pub status: UpdateStatusDto,
    pub available_update: Option<AvailableUpdateDto>,
    pub error: Option<String>,
    pub channel_url: String,
}

#[derive(Clone, Debug)]
pub struct AppSnapshot {
    pub profile: SnapshotProfileDto,
    pub bootstrap: BootstrapStateDto,
    pub operation: Option<String>,
    pub can_mutate: bool,
    pub shutdown_state: ShutdownStateDto,
    pub build_info: BuildInfoDto,
    pub client_config: ClientConfigDto,
    pub session: SessionSnapshot,
    pub room: RoomSnapshot,
    pub room_history: Vec<RoomHistoryEntryDto>,
    pub restore_history_id: Option<u64>,
    pub launch: LaunchProgressDto,
    pub hook: HookSnapshot,
    pub counters: CountersDto,
    pub connection_tests: Vec<ConnectionTestDto>,
    pub logs: Vec<LogEntryDto>,
    pub lan_adapters: Vec<LanAdapterDto>,
    pub lan_join_endpoints: Vec<String>,
    pub bootstrap_error: Option<String>,
    pub update: UpdateSnapshotDto,
}

#[derive(Clone, Debug)]
pub struct BuildInfoDto {
    pub version: String,
    pub git_hash: Option<String>,
    pub version_label: String,
    pub release_version: String,
    pub relay_protocol: String,
    pub direct_protocol: String,
    pub license: String,
    pub source_url: String,
}

#[derive(Clone, Debug)]
pub struct ClientConfigDto {
    pub selected_relay_id: Option<String>,
    pub selected_steam_id64: Option<String>,
    pub mode: SessionModeDto,
    pub transport: TransportSelection,
    pub relays: Vec<RelayDto>,
    pub accounts: Vec<SteamAccountDto>,
    pub warnings: Vec<String>,
}

#[derive(Clone, Debug)]
pub struct RelayDto {
    pub id: String,
    pub name: String,
    pub host: String,
    pub port: u32,
    pub supports_udp: bool,
    pub supports_tcp: bool,
    pub default_transport: TransportSelection,
}

#[derive(Clone, Debug)]
pub struct RelayDraft {
    pub name: String,
    pub host: String,
    pub port: u32,
    pub supports_udp: bool,
    pub supports_tcp: bool,
    pub default_transport: TransportSelection,
}

#[derive(Clone, Debug)]
pub struct SteamAccountDto {
    pub steam_id64: String,
    pub display_name: String,
    pub most_recent: bool,
    pub is_manual: bool,
}

#[derive(Clone, Debug)]
pub struct SteamIdentityMismatchDto {
    pub room_steam_id64: String,
    pub game_steam_id64: String,
}

#[derive(Clone, Debug)]
pub struct SessionSnapshot {
    pub status: SessionStatusDto,
    pub active_mode: Option<SessionModeDto>,
    pub smoothness: String,
    pub health: Option<String>,
    pub last_stop_reason: Option<String>,
}

#[derive(Clone, Debug)]
pub struct RoomSnapshot {
    pub active: bool,
    pub status: RoomStatusDto,
    pub generation: u64,
    pub route: Option<RoomRouteDto>,
    pub transport: Option<TransportSelection>,
    pub join_code: Option<String>,
    pub members: Vec<RoomMemberDto>,
    pub steam_identity_mismatch: Option<SteamIdentityMismatchDto>,
}

#[derive(Clone, Debug)]
pub struct RoomHistoryEntryDto {
    pub id: u64,
    pub join_code: String,
    pub route: RoomRouteDto,
    pub is_current: bool,
}

#[derive(Clone, Debug)]
pub struct RoomMemberDto {
    pub steam_id64: String,
    pub display_name: String,
    pub connection: String,
    pub latency_ms: Option<u64>,
    pub jitter_ms: Option<u64>,
    pub loss_basis_points: Option<u32>,
    pub is_local: bool,
}

#[derive(Clone, Debug)]
pub struct LaunchProgressDto {
    pub status: LaunchStatusDto,
    pub generation: u64,
    pub display_text: String,
    pub error_text: Option<String>,
    pub terminal: bool,
    pub success: bool,
}

#[derive(Clone, Debug)]
pub struct HookSnapshot {
    pub startup_phase: String,
    pub connection: String,
    pub installation: String,
    pub runtime_active: bool,
    pub version: Option<String>,
    pub reconnects: u32,
    pub malformed_frames: u64,
    pub last_error: Option<String>,
    pub input_delay: Option<i32>,
    pub input_delay_error: Option<String>,
}

#[derive(Clone, Debug)]
pub struct CountersDto {
    pub hook_to_relay: u64,
    pub relay_to_hook: u64,
    pub sent_bytes: u64,
    pub received_bytes: u64,
    pub errors: u64,
    pub reconnect_dropped_packets: u64,
    pub detached_hook_dropped_packets: u64,
    pub detached_relay_dropped_packets: u64,
}

#[derive(Clone, Debug)]
pub struct ConnectionTestDto {
    pub relay_id: Option<String>,
    pub relay_name: Option<String>,
    pub endpoint: String,
    pub transport: TransportSelection,
    pub sent: u32,
    pub received: u32,
    pub median_rtt_ms: Option<u64>,
    pub failure_reason: Option<String>,
}

#[derive(Clone, Debug)]
pub struct LogEntryDto {
    pub timestamp_ms: u64,
    pub level: LogLevelDto,
    pub message: String,
}

#[derive(Clone, Debug)]
pub struct LanAdapterDto {
    pub id: String,
    pub name: String,
    pub interface_index: u32,
    pub addresses: Vec<String>,
    pub recommended: bool,
}

#[flutter_rust_bridge::frb(sync)]
pub fn initialize() -> CommandReceipt {
    if APPLICATION.get().is_some() {
        return rejected("already_initialized", "TractorBeam 已经初始化");
    }
    let (wake_tx, wake_rx) = mpsc::sync_channel::<()>(1);
    let application_wake_tx = wake_tx.clone();
    let application =
        ApplicationHandle::spawn_without_update(move || match application_wake_tx.try_send(()) {
            Ok(()) | Err(TrySendError::Full(()) | TrySendError::Disconnected(())) => {}
        });
    let runtime = Arc::new(BridgeRuntime {
        application: Mutex::new(application),
        state: Mutex::new(BridgeState::default()),
        history: Mutex::new(RoomHistoryStore::load()),
        sinks: Mutex::new(Vec::new()),
        wake_tx,
        revision: AtomicU64::new(0),
    });
    if APPLICATION.set(Arc::clone(&runtime)).is_err() {
        return rejected("already_initialized", "TractorBeam 已经初始化");
    }
    trigger_update_check(&runtime);
    thread::Builder::new()
        .name("tractor-beam-flutter-updates".to_owned())
        .spawn(move || {
            let mut last_publish = Instant::now()
                .checked_sub(BACKGROUND_UPDATE_INTERVAL)
                .unwrap_or_else(Instant::now);
            let mut last_critical = None;
            while wake_rx.recv().is_ok() {
                let critical = critical_update_state(&runtime);
                let urgent = last_critical != Some(critical);
                let interval = match critical.profile {
                    SnapshotProfileDto::Full | SnapshotProfileDto::Unknown => Duration::ZERO,
                    SnapshotProfileDto::Lightweight => LIGHTWEIGHT_UPDATE_INTERVAL,
                    SnapshotProfileDto::Background => BACKGROUND_UPDATE_INTERVAL,
                };
                if !urgent {
                    if let Some(remaining) = interval.checked_sub(last_publish.elapsed()) {
                        thread::sleep(remaining);
                        while wake_rx.try_recv().is_ok() {}
                    }
                }
                publish_update(&runtime);
                last_publish = Instant::now();
                last_critical = Some(critical_update_state(&runtime));
                if runtime
                    .application
                    .lock()
                    .expect("application lock")
                    .snapshot()
                    .shutdown_complete
                {
                    break;
                }
            }
        })
        .map_or_else(
            |_| rejected("publisher_unavailable", "无法启动状态推送线程"),
            |_| accepted(),
        )
}

fn critical_update_state(runtime: &BridgeRuntime) -> CriticalUpdateState {
    let snapshot = runtime
        .application
        .lock()
        .expect("application lock")
        .snapshot();
    let state = runtime.state.lock().expect("state lock");
    CriticalUpdateState {
        profile: state.snapshot_profile,
        session: snapshot.runtime.status,
        shutdown_complete: snapshot.shutdown_complete,
        launch: map_launch_progress(&snapshot.runtime, &state).status,
        room: state.room_status,
        update: state.update_status,
    }
}

/// Registers a Dart stream sink and immediately publishes the latest snapshot.
///
/// Poisoned synchronization primitives indicate an unrecoverable process-level
/// invariant violation and are intentionally treated as fatal.
///
/// # Panics
///
/// Panics if an internal application, state, or sink mutex was poisoned.
pub fn updates(sink: StreamSink<AppUpdate>) {
    let Some(runtime) = APPLICATION.get() else {
        let _ = sink.add(AppUpdate {
            revision: 0,
            snapshot: unavailable_snapshot("应用尚未初始化"),
            events: vec![event("not_initialized", false, "应用尚未初始化", None)],
        });
        return;
    };
    runtime.sinks.lock().expect("sink lock").push(sink);
    publish_update(runtime);
}

#[flutter_rust_bridge::frb(sync)]
pub fn set_snapshot_profile(profile: SnapshotProfileDto) -> CommandReceipt {
    let Some(runtime) = APPLICATION.get() else {
        return not_initialized();
    };
    if profile == SnapshotProfileDto::Unknown {
        return rejected("unknown_snapshot_profile", "不支持的界面快照模式");
    }
    runtime.state.lock().expect("state lock").snapshot_profile = profile;
    match runtime.wake_tx.try_send(()) {
        Ok(()) | Err(TrySendError::Full(())) => accepted(),
        Err(TrySendError::Disconnected(())) => {
            rejected("publisher_unavailable", "状态推送线程不可用")
        }
    }
}

#[flutter_rust_bridge::frb(sync)]
pub fn retry_bootstrap() -> CommandReceipt {
    submit(|app, _| app.retry_bootstrap())
}

fn validate_select_relay(snapshot: &ApplicationSnapshot) -> Result<(), Box<CommandReceipt>> {
    let session_active = snapshot.runtime.status != SessionStatus::Idle;
    let room_active = snapshot.room_active();
    if session_active && room_active {
        return Err(Box::new(rejected(
            "room_or_session_active",
            "请先退出游戏并离开房间再切换 Relay 节点",
        )));
    }
    if session_active {
        return Err(Box::new(rejected(
            "room_or_session_active",
            "请先退出游戏再切换 Relay 节点",
        )));
    }
    if room_active {
        return Err(Box::new(rejected(
            "room_or_session_active",
            "请先退出房间再切换 Relay 节点",
        )));
    }
    Ok(())
}

#[flutter_rust_bridge::frb(sync)]
pub fn select_relay(relay_id: Option<String>) -> CommandReceipt {
    let Some(runtime) = APPLICATION.get() else {
        return not_initialized();
    };
    let (snapshot, _) = snapshot_and_draft(runtime);
    if let Err(receipt) = validate_select_relay(&snapshot) {
        return *receipt;
    }
    if let Err(error) = mutate_draft(|state| state.selected_relay_id = relay_id) {
        return *error;
    }
    persist_selection()
}

#[flutter_rust_bridge::frb(sync)]
pub fn select_steam_account(steam_id64: Option<String>) -> CommandReceipt {
    let Some(runtime) = APPLICATION.get() else {
        return not_initialized();
    };
    {
        let mut state = runtime.state.lock().expect("state lock");
        state.selected_steam_id64 = steam_id64.clone();
    }
    let persist_res = persist_selection();
    if !persist_res.accepted {
        return persist_res;
    }

    let (snapshot, state) = snapshot_and_draft(runtime);
    if snapshot.room_active()
        && steam_id64.is_some()
        && let Some(RoomSecret::Relay { .. }) = &state.room
    {
        if let Ok((config, selection)) = build_session_config(&snapshot, &state) {
            let queued = runtime
                .application
                .lock()
                .expect("application lock")
                .rejoin_relay_room(config, selection);
            if !queued {
                return rejected("rejoin_failed", "重新加入中继房间失败");
            }
        }
    }
    publish_update(runtime);
    accepted()
}

#[flutter_rust_bridge::frb(sync)]
pub fn use_game_steam_account() -> CommandReceipt {
    let Some(runtime) = APPLICATION.get() else {
        return not_initialized();
    };
    let snapshot = runtime
        .application
        .lock()
        .expect("application lock")
        .snapshot();
    let Some(mismatch) = snapshot.runtime.steam_identity_mismatch else {
        return rejected("no_mismatch", "未检测到 Steam 账号不一致");
    };
    let game_id = mismatch.game_steam_id64.to_string();
    {
        let mut state = runtime.state.lock().expect("state lock");
        state.selected_steam_id64 = Some(game_id);
    }
    let persist_res = persist_selection();
    if !persist_res.accepted {
        return persist_res;
    }

    let (snapshot, state) = snapshot_and_draft(runtime);
    if snapshot.room_active()
        && let Some(RoomSecret::Relay { .. }) = &state.room
    {
        if let Ok((config, selection)) = build_session_config(&snapshot, &state) {
            let queued = runtime
                .application
                .lock()
                .expect("application lock")
                .rejoin_relay_room(config, selection);
            if queued {
                publish_update(runtime);
                return accepted();
            }
        }
    }
    publish_update(runtime);
    accepted()
}

#[flutter_rust_bridge::frb(sync)]
pub fn delete_manual_steam_account(steam_id64: String) -> CommandReceipt {
    let Some(runtime) = APPLICATION.get() else {
        return not_initialized();
    };
    let Some(path) = bundle_config_path() else {
        return rejected("config_path_unavailable", "无法确定配置文件位置");
    };
    let loaded = match delete_client_manual_steam_account_to(&path, &steam_id64) {
        Ok(loaded) => loaded,
        Err(_) => return rejected("config_delete_failed", "Steam 账号配置删除失败"),
    };
    {
        let mut state = runtime.state.lock().expect("state lock");
        state.selected_steam_id64 = loaded.config.selected_steam_id64.clone();
        state.manual_steam_accounts = loaded.config.manual_steam_accounts;
    }
    let (snapshot, state) = snapshot_and_draft(runtime);
    if snapshot.room_active()
        && state.selected_steam_id64.is_some()
        && let Some(RoomSecret::Relay { .. }) = &state.room
    {
        let id_changed = snapshot.runtime.relay_room_steam_id64.map_or(false, |id| {
            state.selected_steam_id64.as_deref() != Some(&id.to_string())
        });
        if id_changed {
            if let Ok((config, selection)) = build_session_config(&snapshot, &state) {
                let queued = runtime
                    .application
                    .lock()
                    .expect("application lock")
                    .rejoin_relay_room(config, selection);
                if !queued {
                    return rejected("rejoin_failed", "重新加入中继房间失败");
                }
            }
        }
    }
    publish_update(runtime);
    accepted()
}

#[flutter_rust_bridge::frb(sync)]
pub fn save_manual_steam_account(steam_id64: String, display_name: String) -> CommandReceipt {
    let Some(runtime) = APPLICATION.get() else {
        return not_initialized();
    };
    let Some(path) = bundle_config_path() else {
        return rejected("config_path_unavailable", "无法确定配置文件位置");
    };
    let loaded = match save_client_manual_steam_account_to(
        &path,
        ManualSteamAccount {
            steam_id64,
            display_name,
        },
    ) {
        Ok(loaded) => loaded,
        Err(tractor_beam_core::ClientConfigError::InvalidSteamAccount(_)) => {
            return rejected("invalid_steam_account", "Steam 用户名和 ID64 格式无效");
        }
        Err(_) => return rejected("config_save_failed", "Steam 账号配置保存失败"),
    };
    {
        let mut state = runtime.state.lock().expect("state lock");
        state.selected_steam_id64 = loaded.config.selected_steam_id64.clone();
        state.manual_steam_accounts = loaded.config.manual_steam_accounts;
    }
    let (snapshot, state) = snapshot_and_draft(runtime);
    if snapshot.room_active()
        && let Some(RoomSecret::Relay { .. }) = &state.room
    {
        let id_changed = snapshot.runtime.relay_room_steam_id64.map_or(false, |id| {
            state.selected_steam_id64.as_deref() != Some(&id.to_string())
        });
        if id_changed {
            if let Ok((config, selection)) = build_session_config(&snapshot, &state) {
                let queued = runtime
                    .application
                    .lock()
                    .expect("application lock")
                    .rejoin_relay_room(config, selection);
                if !queued {
                    return rejected("rejoin_failed", "重新加入中继房间失败");
                }
            }
        }
    }
    publish_update(runtime);
    accepted()
}

#[flutter_rust_bridge::frb(sync)]
pub fn set_session_mode(mode: SessionModeDto) -> CommandReceipt {
    let Some(value) = mode_from_dto(mode) else {
        return rejected("unknown_enum", "不支持的会话模式");
    };
    if let Err(error) = mutate_draft(|state| state.mode = Some(value)) {
        return *error;
    }
    persist_preferences()
}

#[flutter_rust_bridge::frb(sync)]
pub fn set_transport(transport: TransportSelection) -> CommandReceipt {
    if transport == TransportSelection::Unknown {
        return rejected("unknown_enum", "不支持的传输协议");
    }
    if let Err(error) = mutate_draft(|state| state.transport = transport) {
        return *error;
    }
    persist_preferences()
}

#[flutter_rust_bridge::frb(sync)]
pub fn restore_default_preferences() -> CommandReceipt {
    if let Err(error) = mutate_draft(|state| {
        state.mode = Some(SessionMode::Pure);
        state.transport = TransportSelection::RelayDefault;
    }) {
        return *error;
    }
    persist_preferences()
}

#[flutter_rust_bridge::frb(sync)]
pub fn add_relay(relay: RelayDraft) -> CommandReceipt {
    let input = match relay_input(relay) {
        Ok(value) => value,
        Err(error) => return *error,
    };
    let Some(runtime) = APPLICATION.get() else {
        return not_initialized();
    };
    runtime.state.lock().expect("state lock").pending_relay_op = Some(PendingRelayOperation::Add);
    let result = save_relay(RelayCatalogChange::Add(input));
    if !result.accepted {
        runtime.state.lock().expect("state lock").pending_relay_op = None;
    }
    result
}

#[flutter_rust_bridge::frb(sync)]
pub fn update_relay(relay_id: String, relay: RelayDraft) -> CommandReceipt {
    let input = match relay_input(relay) {
        Ok(value) => value,
        Err(error) => return *error,
    };
    let Some(runtime) = APPLICATION.get() else {
        return not_initialized();
    };
    runtime.state.lock().expect("state lock").pending_relay_op =
        Some(PendingRelayOperation::Update);
    let result = save_relay(RelayCatalogChange::Update {
        id: relay_id,
        relay: input,
    });
    if !result.accepted {
        runtime.state.lock().expect("state lock").pending_relay_op = None;
    }
    result
}

#[flutter_rust_bridge::frb(sync)]
pub fn delete_relay(relay_id: String) -> CommandReceipt {
    let Some(runtime) = APPLICATION.get() else {
        return not_initialized();
    };
    let (snapshot, _) = snapshot_and_draft(runtime);
    let relay_name = snapshot
        .loaded_config
        .as_ref()
        .and_then(|c| c.config.relays.iter().find(|r| r.id == relay_id))
        .map(|r| r.name.clone())
        .unwrap_or_else(|| relay_id.clone());

    runtime.state.lock().expect("state lock").pending_relay_op =
        Some(PendingRelayOperation::Delete { relay_name });
    let result = save_relay(RelayCatalogChange::Delete { id: relay_id });
    if !result.accepted {
        runtime.state.lock().expect("state lock").pending_relay_op = None;
    }
    result
}

#[flutter_rust_bridge::frb(sync)]
pub fn refresh_accounts() -> CommandReceipt {
    submit(|app, _| app.refresh_accounts())
}

#[flutter_rust_bridge::frb(sync)]
pub fn test_relay_latency() -> CommandReceipt {
    let Some(runtime) = APPLICATION.get() else {
        return not_initialized();
    };
    let (snapshot, state) = snapshot_and_draft(runtime);
    let Some(config) = snapshot.loaded_config.as_ref() else {
        return rejected("bootstrap_not_ready", "配置尚未就绪");
    };
    let Some(selected_id) = state.selected_relay_id.as_deref() else {
        return rejected("relay_required", "请先选择 Relay 服务器");
    };
    let Some(_) = config
        .config
        .relays
        .iter()
        .find(|relay| relay.id == selected_id)
    else {
        return rejected("relay_required", "请先选择 Relay 服务器");
    };
    let targets = config
        .config
        .relays
        .iter()
        .map(|relay| LightPingTarget {
            relay_id: Some(relay.id.clone()),
            relay_name: Some(relay.name.clone()),
            endpoint: relay.endpoint.clone(),
            transport: effective_transport(&state, relay),
        })
        .collect();
    let targets = deduplicate_light_ping_targets(targets);
    receipt(
        runtime
            .application
            .lock()
            .expect("application lock")
            .start_light_ping(targets),
    )
}

#[flutter_rust_bridge::frb(sync)]
pub fn create_relay_room() -> CommandReceipt {
    let Some(runtime) = APPLICATION.get() else {
        return not_initialized();
    };
    let (snapshot, mut state) = snapshot_and_draft(runtime);
    if snapshot.room_active() {
        return rejected("room_already_active", "请先退出当前房间");
    }
    let Ok((relay, steam_id, display_name)) = selected_identity_and_relay(&snapshot, &state) else {
        return rejected("selection_incomplete", "请选择 Relay 和 Steam 账号");
    };
    let credential = SessionCredential::generate();
    let route = ExternalRelayConfig {
        relay: relay.endpoint.clone(),
        relay_name: Some(relay.name.clone()),
        transport: effective_transport(&state, relay),
        session_credential: credential,
    };
    let code = match JoinCode::ExternalRelay(RelayJoinCode {
        relay_id: Some(relay.id.clone()),
        relay_host: relay.endpoint.host.clone(),
        relay_port: relay.endpoint.port,
        session_credential: credential,
    })
    .encode()
    {
        Ok(code) => code,
        Err(error) => return rejected("join_code_failed", &error.to_string()),
    };
    state.pending_room = Some(RoomSecret::Relay {
        route: route.clone(),
        join_code: code,
    });
    state.room_status = RoomStatusDto::Creating;
    *runtime.state.lock().expect("state lock") = state;
    let queued = runtime
        .application
        .lock()
        .expect("application lock")
        .join_relay_room(route.clone(), steam_id, display_name);
    if !queued {
        let mut state = runtime.state.lock().expect("state lock");
        state.pending_room = None;
        state.room_status = RoomStatusDto::Idle;
    } else {
        publish_update(runtime);
    }
    receipt(queued)
}

#[flutter_rust_bridge::frb(sync)]
pub fn enumerate_lan_adapters() -> CommandReceipt {
    submit(|app, _| app.enumerate_lan_adapters())
}

#[flutter_rust_bridge::frb(sync)]
pub fn create_lan_room(adapter_ids: Vec<String>) -> CommandReceipt {
    let Some(runtime) = APPLICATION.get() else {
        return not_initialized();
    };
    let (snapshot, state) = snapshot_and_draft(runtime);
    if snapshot.room_active() {
        return rejected("room_already_active", "请先退出当前房间");
    }
    let Ok((steam_id, display_name)) = selected_identity(&snapshot, &state) else {
        return rejected("account_required", "请选择 Steam 账号");
    };
    let selected = state
        .lan_adapters
        .into_iter()
        .filter(|adapter| adapter_ids.iter().any(|id| id == &adapter.adapter_id))
        .collect::<Vec<_>>();
    if selected.is_empty() {
        return rejected("lan_adapter_required", "请至少选择一个网卡");
    }
    if selected.len() > 8 {
        return rejected("too_many_lan_adapters", "最多选择八个网卡");
    }
    runtime.state.lock().expect("state lock").room_status = RoomStatusDto::Creating;
    let queued = runtime
        .application
        .lock()
        .expect("application lock")
        .create_lan_room(steam_id, display_name, selected);
    if queued {
        publish_update(runtime);
    } else {
        runtime.state.lock().expect("state lock").room_status = RoomStatusDto::Idle;
    }
    receipt(queued)
}

#[flutter_rust_bridge::frb(sync)]
pub fn join_room(join_code: String, selected_lan_endpoint: Option<String>) -> CommandReceipt {
    let Some(runtime) = APPLICATION.get() else {
        return not_initialized();
    };
    let (snapshot, mut state) = snapshot_and_draft(runtime);
    if snapshot.room_active() {
        return rejected("room_already_active", "请先退出当前房间");
    }
    let Ok((steam_id, display_name)) = selected_identity(&snapshot, &state) else {
        return rejected("account_required", "请选择 Steam 账号");
    };
    match JoinCode::decode(&join_code) {
        Ok(JoinCode::ExternalRelay(code)) => {
            let route = ExternalRelayConfig {
                relay: code.endpoint(),
                relay_name: code.relay_id.clone(),
                transport: relay_transport_for_endpoint(
                    &snapshot,
                    &state,
                    code.relay_id.as_deref(),
                ),
                session_credential: code.session_credential,
            };
            state.pending_room = Some(RoomSecret::Relay {
                route: route.clone(),
                join_code,
            });
            state.room_status = RoomStatusDto::Joining;
            *runtime.state.lock().expect("state lock") = state;
            let queued = runtime
                .application
                .lock()
                .expect("application lock")
                .join_relay_room(route.clone(), steam_id.to_string(), display_name);
            if !queued {
                let mut state = runtime.state.lock().expect("state lock");
                state.pending_room = None;
                state.room_status = RoomStatusDto::Idle;
            } else {
                publish_update(runtime);
            }
            receipt(queued)
        }
        Ok(JoinCode::LanDirect(invitation)) => {
            if let Some(endpoint) = selected_lan_endpoint {
                let Ok(endpoint) = endpoint.parse::<SocketAddr>() else {
                    return rejected("invalid_lan_endpoint", "局域网端点无效");
                };
                let credential = invitation.session_credential;
                state.pending_room = Some(RoomSecret::Lan {
                    credential,
                    join_code,
                });
                state.room_status = RoomStatusDto::Joining;
                state.pending_lan = None;
                *runtime.state.lock().expect("state lock") = state;
                let queued = runtime
                    .application
                    .lock()
                    .expect("application lock")
                    .join_lan_room(steam_id, display_name, invitation, endpoint);
                if !queued {
                    let mut state = runtime.state.lock().expect("state lock");
                    state.pending_room = None;
                    state.room_status = RoomStatusDto::Idle;
                } else {
                    publish_update(runtime);
                }
                receipt(queued)
            } else {
                state.pending_lan = Some(PendingLanJoin {
                    invitation: invitation.clone(),
                    endpoints: Vec::new(),
                    join_code,
                });
                state.room_status = RoomStatusDto::Joining;
                *runtime.state.lock().expect("state lock") = state;
                receipt(
                    runtime
                        .application
                        .lock()
                        .expect("application lock")
                        .probe_lan_join(invitation),
                )
            }
        }
        Err(error) => rejected("invalid_join_code", &format!("联机码无效：{error}")),
    }
}

/// Retry a Relay invitation over TCP without changing the saved default.
#[flutter_rust_bridge::frb(sync)]
pub fn retry_relay_room_with_tcp(join_code: String) -> CommandReceipt {
    let Some(runtime) = APPLICATION.get() else {
        return not_initialized();
    };
    let (snapshot, mut state) = snapshot_and_draft(runtime);
    if snapshot.room_active() {
        return rejected("room_already_active", "请先退出当前房间");
    }
    let Ok((steam_id, display_name)) = selected_identity(&snapshot, &state) else {
        return rejected("account_required", "请选择 Steam 账号");
    };
    let Ok(JoinCode::ExternalRelay(code)) = JoinCode::decode(&join_code) else {
        return rejected("relay_join_code_required", "该联机码不是 Relay 房间");
    };
    let route = ExternalRelayConfig {
        relay: code.endpoint(),
        relay_name: code.relay_id.clone(),
        transport: TransportChoice::Tcp,
        session_credential: code.session_credential,
    };
    state.pending_room = Some(RoomSecret::Relay {
        route: route.clone(),
        join_code,
    });
    state.room_status = RoomStatusDto::Joining;
    *runtime.state.lock().expect("state lock") = state;
    let queued = runtime
        .application
        .lock()
        .expect("application lock")
        .join_relay_room(route, steam_id.to_string(), display_name);
    if !queued {
        let mut state = runtime.state.lock().expect("state lock");
        state.pending_room = None;
        state.room_status = RoomStatusDto::Idle;
    } else {
        publish_update(runtime);
    }
    receipt(queued)
}

#[flutter_rust_bridge::frb(sync)]
pub fn join_history_room(history_id: u64) -> CommandReceipt {
    let Some(runtime) = APPLICATION.get() else {
        return not_initialized();
    };
    let Some(entry) = runtime
        .history
        .lock()
        .expect("history lock")
        .entry(history_id)
    else {
        return rejected("room_history_missing", "该历史联机码已不存在");
    };
    join_room(entry.join_code, None)
}

#[flutter_rust_bridge::frb(sync)]
pub fn continue_lan_join(selected_lan_endpoint: String) -> CommandReceipt {
    let Some(runtime) = APPLICATION.get() else {
        return not_initialized();
    };
    let join_code = runtime
        .state
        .lock()
        .expect("state lock")
        .pending_lan
        .as_ref()
        .map(|pending| pending.join_code.clone());
    let Some(join_code) = join_code else {
        return rejected("lan_join_not_pending", "当前没有等待选择端点的局域网房间");
    };
    join_room(join_code, Some(selected_lan_endpoint))
}

#[flutter_rust_bridge::frb(sync)]
pub fn leave_room() -> CommandReceipt {
    let Some(runtime) = APPLICATION.get() else {
        return not_initialized();
    };
    let _ = runtime
        .history
        .lock()
        .expect("history lock")
        .clear_restore();
    runtime.state.lock().expect("state lock").room_status = RoomStatusDto::Leaving;
    runtime
        .application
        .lock()
        .expect("application lock")
        .leave_room();
    publish_update(runtime);
    accepted()
}

#[flutter_rust_bridge::frb(sync)]
pub fn start_game() -> CommandReceipt {
    let Some(runtime) = APPLICATION.get() else {
        return not_initialized();
    };
    let (snapshot, state) = snapshot_and_draft(runtime);
    if !snapshot.room_active() {
        return rejected("room_required", "请先加入联机房间");
    }
    let Ok((steam_id, display_name)) = selected_identity(&snapshot, &state) else {
        return rejected("account_required", "请选择 Steam 账号");
    };
    let Some(room) = state.room.as_ref() else {
        return rejected("room_state_missing", "房间状态不可用");
    };
    let route = match room {
        RoomSecret::Relay { route, .. } => SessionRouteConfig::ExternalRelay(route.clone()),
        RoomSecret::Lan { credential, .. } => SessionRouteConfig::LanDirect(LanDirectConfig {
            session_credential: *credential,
            room: None,
        }),
    };
    let mode = state.mode.unwrap_or(SessionMode::Pure);
    let health = snapshot
        .loaded_config
        .as_ref()
        .map_or_else(Default::default, |c| c.config.session_health);
    let selection = ClientConfigSelection {
        selected_relay: state.selected_relay_id.clone(),
        selected_steam_id64: state.selected_steam_id64.clone(),
    };
    {
        let mut draft = runtime.state.lock().expect("state lock");
        draft.launch_generation = draft.launch_generation.saturating_add(1);
        draft.launch_pending = true;
        draft.launch_cancel_requested = false;
        draft.launch_cancelled = false;
        draft.launch_error = None;
        draft.launch_started_at = Some(Instant::now());
    }
    let queued = runtime.application.lock().expect("application lock").start(
        SessionConfig {
            route,
            mode,
            steam_id64: steam_id.to_string(),
            display_name,
            session_health: health,
        },
        selection,
    );
    if queued {
        publish_update(runtime);
    } else {
        let mut draft = runtime.state.lock().expect("state lock");
        draft.launch_pending = false;
        draft.launch_started_at = None;
    }
    receipt(queued)
}

/// Cancels only an in-flight launch. This deliberately does not expose the
/// application's general stop-session command to Flutter: once Hook is ready,
/// stopping gameplay is a separate user action with different consequences.
#[flutter_rust_bridge::frb(sync)]
pub fn cancel_launch() -> CommandReceipt {
    let Some(runtime) = APPLICATION.get() else {
        return not_initialized();
    };
    let application = runtime.application.lock().expect("application lock");
    let snapshot = application.snapshot();
    let mut state = runtime.state.lock().expect("state lock");
    if state.launch_cancel_requested {
        return rejected("launch_cancel_pending", "正在取消游戏启动，请稍候");
    }
    let status = map_launch_progress(&snapshot.runtime, &state).status;
    if !matches!(
        status,
        LaunchStatusDto::Starting
            | LaunchStatusDto::WaitingForGame
            | LaunchStatusDto::Injecting
            | LaunchStatusDto::WaitingForHook
    ) {
        return rejected("launch_not_active", "当前没有可以取消的启动流程");
    }
    if !application.stop_session() {
        return rejected("queue_busy", "命令队列繁忙，请稍后重试");
    }
    state.launch_cancel_requested = true;
    state.launch_cancelled = false;
    state.launch_started_at = None;
    state.launch_error = None;
    drop(state);
    drop(application);
    publish_update(runtime);
    accepted()
}

#[flutter_rust_bridge::frb(sync)]
pub fn read_input_delay() -> CommandReceipt {
    submit(|app, _| app.read_input_delay())
}

#[flutter_rust_bridge::frb(sync)]
pub fn write_input_delay(value: i32) -> CommandReceipt {
    submit(|app, _| app.write_input_delay(value))
}

#[flutter_rust_bridge::frb(sync)]
pub fn refresh_hook_status() -> CommandReceipt {
    submit(|app, _| app.start_hook_receive_probe())
}

#[flutter_rust_bridge::frb(sync)]
pub fn open_log_directory() -> CommandReceipt {
    submit(|app, _| app.open_log_directory())
}

#[flutter_rust_bridge::frb(sync)]
pub fn export_diagnostics_bundle() -> CommandReceipt {
    submit(|app, _| app.export_diagnostics_bundle())
}

#[flutter_rust_bridge::frb(sync)]
pub fn clear_logs() -> CommandReceipt {
    submit(|app, _| app.clear_logs())
}

#[flutter_rust_bridge::frb(sync)]
pub fn shutdown() -> CommandReceipt {
    let Some(runtime) = APPLICATION.get() else {
        return not_initialized();
    };
    runtime
        .application
        .lock()
        .expect("application lock")
        .request_shutdown();
    accepted()
}

#[flutter_rust_bridge::frb(sync)]
pub fn bridge_version() -> String {
    tractor_beam_core::build_info::version_label()
}

fn trigger_update_check(runtime: &Arc<BridgeRuntime>) {
    let mut state = runtime.state.lock().expect("state lock");
    if state.update_status == UpdateStatusDto::Checking {
        return;
    }
    state.update_status = UpdateStatusDto::Checking;
    state.update_error = None;
    drop(state);
    let _ = runtime.wake_tx.try_send(());

    let runtime = Arc::clone(runtime);
    let _ = thread::Builder::new()
        .name("tractor-beam-flutter-update-check".to_owned())
        .spawn(move || {
            let result = check_for_update_with_channel(flutter_release_version(), FLUTTER_CHANNEL);
            let mut state = runtime.state.lock().expect("state lock");
            match result {
                Ok(Some(update)) => {
                    state.update_status = UpdateStatusDto::Available;
                    state.available_update = Some(AvailableUpdateDto {
                        version: update.version,
                        url: update.url,
                    });
                    state.update_error = None;
                }
                Ok(None) => {
                    state.update_status = UpdateStatusDto::UpToDate;
                    state.available_update = None;
                    state.update_error = None;
                }
                Err(err) => {
                    state.update_status = UpdateStatusDto::Failed;
                    state.update_error = Some(err);
                }
            }
            drop(state);
            let _ = runtime.wake_tx.try_send(());
        });
}

#[flutter_rust_bridge::frb(sync)]
pub fn check_update() -> CommandReceipt {
    let Some(runtime) = APPLICATION.get() else {
        return not_initialized();
    };
    trigger_update_check(runtime);
    accepted()
}

fn publish_update(runtime: &BridgeRuntime) {
    let (snapshot, events) = {
        let application = runtime.application.lock().expect("application lock");
        (application.snapshot(), application.drain_events())
    };
    let mut state = runtime.state.lock().expect("state lock");
    initialize_draft(&snapshot, &mut state);
    normalize_selections(&snapshot, &mut state);
    let mut mapped_events = process_events(runtime, &snapshot, &mut state, events);
    enforce_launch_timeout(runtime, &snapshot, &mut state, &mut mapped_events);
    let revision = runtime.revision.fetch_add(1, Ordering::Relaxed) + 1;
    let update = AppUpdate {
        revision,
        snapshot: map_snapshot(&snapshot, &state, runtime),
        events: mapped_events,
    };
    runtime
        .sinks
        .lock()
        .expect("sink lock")
        .retain(|sink| sink.add(update.clone()).is_ok());
}

#[allow(clippy::too_many_lines)]
fn process_events(
    runtime: &BridgeRuntime,
    snapshot: &ApplicationSnapshot,
    state: &mut BridgeState,
    events: Vec<ApplicationEvent>,
) -> Vec<AppEvent> {
    let mut result = Vec::new();
    for item in events {
        match item {
            ApplicationEvent::StartFinished(value) => match value {
                Ok(()) => result.push(event("start_game", true, "游戏启动流程已开始", None)),
                Err(error) => {
                    let display = localize_launch_error(&error.to_string());
                    state.launch_pending = false;
                    state.launch_started_at = None;
                    state.launch_error = Some(display.clone());
                    result.push(event("start_game", false, &display, None));
                }
            },
            ApplicationEvent::SessionStopped => {
                if state.launch_cancel_requested {
                    state.launch_cancel_requested = false;
                    state.launch_cancelled = true;
                    state.launch_error = None;
                    result.push(event(
                        "launch_cancelled",
                        true,
                        "已取消游戏启动；已经打开的游戏不会被自动关闭",
                        None,
                    ));
                }
                state.launch_pending = false;
                state.launch_started_at = None;
            }
            ApplicationEvent::RoomLeft => {
                state.room = None;
                state.pending_room = None;
                state.pending_lan = None;
                state.room_status = RoomStatusDto::Idle;
                result.push(event("room_left", true, "已退出当前房间", None));
            }
            ApplicationEvent::RelayRoomJoined(value) => match value {
                Ok(()) => {
                    if let Some(room) = state.pending_room.take() {
                        state.room = Some(room);
                    }
                    state.room_generation = state.room_generation.saturating_add(1);
                    state.room_status = RoomStatusDto::Active;
                    result.push(event("relay_room_joined", true, "已加入 Relay 房间", None));
                    record_active_room(runtime, state, &mut result);
                }
                Err(error) => {
                    let failed_join_code = match state.pending_room.as_ref() {
                        Some(RoomSecret::Relay { join_code, .. }) => Some(join_code.clone()),
                        _ => None,
                    };
                    let udp_fallback_suggested = matches!(
                        state.pending_room.as_ref(),
                        Some(RoomSecret::Relay { route, .. })
                            if route.transport == TransportChoice::Udp
                    ) && is_udp_fallback_error(&error.to_string());
                    state.pending_room = None;
                    state.room = None;
                    state.room_status = RoomStatusDto::Failed;
                    let mut failure = event(
                        "relay_room_joined",
                        false,
                        &localize_network_error(&error.to_string()),
                        failed_join_code,
                    );
                    if udp_fallback_suggested {
                        "event.relay_room_joined.udp_unavailable"
                            .clone_into(&mut failure.message.key);
                    }
                    result.push(failure);
                }
            },
            ApplicationEvent::AccountsRefreshed => {
                result.push(event("accounts_refreshed", true, "Steam 账号已刷新", None));
            }
            ApplicationEvent::ReadinessProbeStarted(value) => result.push(result_event(
                "readiness_probe",
                value.map(|()| "连接测试已开始".to_owned()),
            )),
            ApplicationEvent::HookReceiveProbeStarted(value) => result.push(result_event(
                "hook_probe",
                value.map(|()| "Hook 通信检查已开始".to_owned()),
            )),
            ApplicationEvent::LightPingStarted(value) => result.push(result_event(
                "latency_test",
                value.map(|()| "延迟测试已开始".to_owned()),
            )),
            ApplicationEvent::InputDelayReadFinished(value) => match value {
                Ok(report) => result.push(event(
                    "input_delay_read",
                    true,
                    "已从游戏读取输入延迟",
                    Some(report.value.to_string()),
                )),
                Err(error) => {
                    result.push(event(
                        "input_delay_read",
                        false,
                        &localize_input_delay_error(&error, false),
                        None,
                    ));
                }
            },
            ApplicationEvent::InputDelayWriteFinished(value) => match value {
                Ok(report) => result.push(event(
                    "input_delay_written",
                    true,
                    "输入延迟已写入游戏",
                    Some(report.value.to_string()),
                )),
                Err(error) => result.push(event(
                    "input_delay_written",
                    false,
                    &localize_input_delay_error(&error, true),
                    None,
                )),
            },
            ApplicationEvent::LogDirectoryOpened(value) => {
                result.push(path_event("log_directory_opened", value));
            }
            ApplicationEvent::DiagnosticsBundleExported(value) => match value {
                Ok(Some(path)) => result.push(event(
                    "diagnostics_exported",
                    true,
                    "诊断包已导出",
                    Some(path.display().to_string()),
                )),
                Ok(None) => result.push(event(
                    "diagnostics_cancelled",
                    true,
                    "已取消导出诊断包",
                    None,
                )),
                Err(error) => result.push(event("diagnostics_exported", false, &error, None)),
            },
            ApplicationEvent::LanAdaptersEnumerated(value) => match value {
                Ok(adapters) => {
                    state.lan_adapters = adapters;
                    result.push(event("lan_adapters", true, "网卡列表已更新", None));
                }
                Err(error) => result.push(event("lan_adapters", false, &error, None)),
            },
            ApplicationEvent::LanProbeFinished(value) => match value {
                Ok((invitation, probes)) if probes.len() == 1 => {
                    let probe = &probes[0];
                    let mut queued = false;
                    if let Ok((steam_id, display_name)) = selected_identity(snapshot, state) {
                        let join_code = JoinCode::LanDirect(invitation.clone())
                            .encode()
                            .unwrap_or_default();
                        let credential = invitation.session_credential;
                        state.pending_room = Some(RoomSecret::Lan {
                            credential,
                            join_code,
                        });
                        queued = runtime
                            .application
                            .lock()
                            .expect("application lock")
                            .join_lan_room(steam_id, display_name, invitation, probe.endpoint);
                        if !queued {
                            state.pending_room = None;
                            state.room_status = RoomStatusDto::Failed;
                        }
                    }
                    state.pending_lan = None;
                    result.push(event(
                        "lan_endpoint_auto_selected",
                        queued,
                        if queued {
                            "已自动选择唯一可达端点"
                        } else {
                            "无法加入自动选择的局域网端点"
                        },
                        queued.then(|| probe.endpoint.to_string()),
                    ));
                }
                Ok((_, probes)) if probes.is_empty() => {
                    state.pending_lan = None;
                    state.pending_room = None;
                    state.room_status = RoomStatusDto::Failed;
                    result.push(event(
                        "lan_unreachable",
                        false,
                        "没有可达的局域网端点",
                        None,
                    ));
                }
                Ok((invitation, probes)) => {
                    let join_code = state
                        .pending_lan
                        .as_ref()
                        .map_or_else(String::new, |pending| pending.join_code.clone());
                    state.pending_lan = Some(PendingLanJoin {
                        invitation,
                        endpoints: probes.iter().map(|p| p.endpoint).collect(),
                        join_code,
                    });
                    result.push(event(
                        "lan_endpoint_selection_required",
                        true,
                        "请选择一个局域网端点",
                        None,
                    ));
                }
                Err(error) => {
                    state.pending_lan = None;
                    state.pending_room = None;
                    state.room_status = RoomStatusDto::Failed;
                    result.push(event(
                        "lan_probe_failed",
                        false,
                        &localize_network_error(&error),
                        None,
                    ));
                }
            },
            ApplicationEvent::LanRoomCreated(value) => match value {
                Ok(code) => {
                    if let Ok(JoinCode::LanDirect(invitation)) = JoinCode::decode(&code) {
                        state.room = Some(RoomSecret::Lan {
                            credential: invitation.session_credential,
                            join_code: code.clone(),
                        });
                    }
                    state.room_generation = state.room_generation.saturating_add(1);
                    state.room_status = RoomStatusDto::Active;
                    result.push(event(
                        "lan_room_created",
                        true,
                        "局域网房间已创建",
                        Some(code),
                    ));
                    record_active_room(runtime, state, &mut result);
                }
                Err(error) => {
                    state.room = None;
                    state.room_status = RoomStatusDto::Failed;
                    result.push(event("lan_room_created", false, &error, None));
                }
            },
            ApplicationEvent::LanRoomJoined(value) => match value {
                Ok(()) => {
                    if let Some(room) = state.pending_room.take() {
                        state.room = Some(room);
                    }
                    state.room_generation = state.room_generation.saturating_add(1);
                    state.room_status = RoomStatusDto::Active;
                    result.push(event("lan_room_joined", true, "已加入局域网房间", None));
                    record_active_room(runtime, state, &mut result);
                }
                Err(error) => {
                    state.pending_room = None;
                    state.room = None;
                    state.room_status = RoomStatusDto::Failed;
                    result.push(event("lan_room_joined", false, &error, None));
                }
            },
            ApplicationEvent::SelectionSaveFailed(error) => {
                result.push(event("config_save_failed", false, &error, None));
            }
            ApplicationEvent::RelayCatalogSaved(value) => {
                let pending_op = std::mem::take(&mut state.pending_relay_op);
                match value {
                    Ok(loaded) => {
                        state
                            .selected_relay_id
                            .clone_from(&loaded.config.selected_relay);
                        let selected = state.selected_relay_id.clone();
                        let (event_name, display_msg) = match &pending_op {
                            Some(PendingRelayOperation::Add) => {
                                ("relay_added", "Relay 节点已添加".to_owned())
                            }
                            Some(PendingRelayOperation::Update) => {
                                ("relay_updated", "Relay 节点已更新".to_owned())
                            }
                            Some(PendingRelayOperation::Delete { .. }) => {
                                if let Some(selected_id) = &selected
                                    && let Some(relay) =
                                        loaded.config.relays.iter().find(|r| r.id == *selected_id)
                                {
                                    (
                                        "relay_deleted",
                                        format!("节点已删除，已切换至：{}", relay.name),
                                    )
                                } else {
                                    ("relay_deleted", "Relay 节点已删除".to_owned())
                                }
                            }
                            None => ("relay_catalog_saved", "Relay 配置已保存".to_owned()),
                        };
                        result.push(event(event_name, true, &display_msg, selected.clone()));
                        if matches!(
                            pending_op,
                            Some(PendingRelayOperation::Add | PendingRelayOperation::Update)
                        ) && let Some(selected_id) = selected
                            && let Some(relay) = loaded
                                .config
                                .relays
                                .iter()
                                .find(|relay| relay.id == selected_id)
                        {
                            let target = LightPingTarget {
                                relay_id: Some(relay.id.clone()),
                                relay_name: Some(relay.name.clone()),
                                endpoint: relay.endpoint.clone(),
                                transport: effective_transport(state, relay),
                            };
                            let queued = runtime
                                .application
                                .lock()
                                .expect("application lock")
                                .start_light_ping(vec![target]);
                            if !queued {
                                result.push(event(
                                    "latency_test",
                                    false,
                                    "Relay 已保存，但延迟测试队列繁忙",
                                    None,
                                ));
                            }
                        }
                    }
                    Err(err) => {
                        let message = format!("Relay 配置保存失败: {err}");
                        result.push(event("relay_catalog_saved", false, &message, None));
                    }
                }
            }
            ApplicationEvent::PreferencesSaved(value) => {
                let message = match &value {
                    Ok(_) => "设置已保存".to_owned(),
                    Err(err) => format!("设置保存失败: {err}"),
                };
                result.push(event("preferences_saved", value.is_ok(), &message, None));
            }
            ApplicationEvent::CommandRejected => result.push(event(
                "command_rejected",
                false,
                "当前正忙，请稍后重试",
                None,
            )),
            ApplicationEvent::ShutdownComplete => result.push(event(
                "shutdown_complete",
                true,
                "TractorBeam 已安全关闭",
                None,
            )),
            ApplicationEvent::ClipboardReadFinished(value) => match value {
                Ok(text) => result.push(event("clipboard_read", true, "已读取剪贴板", Some(text))),
                Err(error) => result.push(event("clipboard_read", false, &error, None)),
            },
            ApplicationEvent::UpdateAvailable(update) => {
                state.update_status = UpdateStatusDto::Available;
                state.available_update = Some(AvailableUpdateDto {
                    version: update.version,
                    url: update.url,
                });
                state.update_error = None;
            }
        }
    }
    result
}

fn record_active_room(runtime: &BridgeRuntime, state: &BridgeState, events: &mut Vec<AppEvent>) {
    let Some(room) = state.room.as_ref() else {
        return;
    };
    let (join_code, route) = match room {
        RoomSecret::Relay { join_code, .. } => (join_code, StoredRoomRoute::Relay),
        RoomSecret::Lan { join_code, .. } => (join_code, StoredRoomRoute::Lan),
    };
    if runtime
        .history
        .lock()
        .expect("history lock")
        .record_success(join_code, route)
        .is_err()
    {
        events.push(event(
            "room_history_save_failed",
            false,
            "房间已连接，但无法保存联机码历史",
            None,
        ));
    }
}

#[allow(clippy::too_many_lines)]
fn map_snapshot(
    snapshot: &ApplicationSnapshot,
    state: &BridgeState,
    bridge_runtime: &BridgeRuntime,
) -> AppSnapshot {
    let profile = state.snapshot_profile;
    let full = profile == SnapshotProfileDto::Full;
    let runtime = &snapshot.runtime;
    let build = tractor_beam_core::build_info::current();
    let config = snapshot.loaded_config.as_ref();
    let mut members = runtime
        .room_peers
        .iter()
        .map(|peer| {
            let quality = runtime
                .room_path_quality
                .iter()
                .find(|quality| quality.steam_id64 == peer.steam_id64);
            RoomMemberDto {
                steam_id64: peer.steam_id64.to_string(),
                display_name: peer
                    .display_name
                    .clone()
                    .unwrap_or_else(|| peer.steam_id64.to_string()),
                connection: format!("{:?}", peer.presence).to_lowercase(),
                latency_ms: quality.and_then(|q| q.median_rtt).map(duration_ms),
                jitter_ms: quality.and_then(|q| q.jitter).map(duration_ms),
                loss_basis_points: quality.and_then(|q| q.loss_basis_points).map(u32::from),
                is_local: false,
            }
        })
        .collect::<Vec<_>>();
    members.extend(runtime.lan_peers.iter().map(|peer| {
        RoomMemberDto {
            steam_id64: peer.peer.identity.steam_id64.to_string(),
            display_name: peer
                .peer
                .display_name
                .clone()
                .unwrap_or_else(|| peer.peer.identity.steam_id64.to_string()),
            connection: format!("{:?}", peer.connection).to_lowercase(),
            latency_ms: None,
            jitter_ms: None,
            loss_basis_points: None,
            is_local: false,
        }
    }));
    if snapshot.room_active() {
        let relay_id_str = runtime.relay_room_steam_id64.map(|id| id.to_string());
        let local_id = state.selected_steam_id64.as_ref().or(relay_id_str.as_ref());
        if let Some(local_id) = local_id {
            let display_name =
                account_display_name(snapshot, state, local_id).unwrap_or_else(|| local_id.clone());
            members.retain(|member| {
                member.steam_id64 != *local_id
                    && relay_id_str
                        .as_ref()
                        .is_none_or(|relay_id| member.steam_id64 != *relay_id)
            });
            let local_member = RoomMemberDto {
                steam_id64: local_id.clone(),
                display_name,
                connection: if runtime.status == SessionStatus::Running {
                    "游戏中".to_owned()
                } else {
                    "已连接".to_owned()
                },
                latency_ms: None,
                jitter_ms: None,
                loss_basis_points: None,
                is_local: true,
            };
            members.insert(0, local_member);
        }
    }
    let mut seen_ids = std::collections::HashSet::new();
    members.retain(|member| seen_ids.insert(member.steam_id64.clone()));
    let room_route = state.room.as_ref().map(|room| match room {
        RoomSecret::Relay { .. } => RoomRouteDto::Relay,
        RoomSecret::Lan { .. } => RoomRouteDto::Lan,
    });
    let room_transport = state.room.as_ref().map(|room| match room {
        RoomSecret::Relay { route, .. } => transport_to_dto(route.transport),
        RoomSecret::Lan { .. } => TransportSelection::Udp,
    });
    let join_code = state.room.as_ref().map(|room| match room {
        RoomSecret::Relay { join_code, .. } | RoomSecret::Lan { join_code, .. } => {
            join_code.clone()
        }
    });
    let input_delay = runtime
        .latest_input_delay_status
        .as_ref()
        .and_then(|status| status.result.as_ref().ok().copied());
    let input_delay_error = runtime
        .latest_input_delay_status
        .as_ref()
        .and_then(|status| status.result.as_ref().err().cloned());
    AppSnapshot {
        profile,
        bootstrap: match snapshot.bootstrap {
            BootstrapState::Initializing => BootstrapStateDto::Initializing,
            BootstrapState::Ready => BootstrapStateDto::Ready,
            BootstrapState::Failed => BootstrapStateDto::Failed,
        },
        operation: snapshot.operation.map(operation_name),
        can_mutate: snapshot.accepts_mutation(),
        shutdown_state: if snapshot.shutdown_complete {
            ShutdownStateDto::Complete
        } else if snapshot.operation == Some(ApplicationOperation::ShuttingDown) {
            ShutdownStateDto::ShuttingDown
        } else {
            ShutdownStateDto::Running
        },
        build_info: BuildInfoDto {
            version: build.version.to_owned(),
            git_hash: build.git_hash.map(str::to_owned),
            version_label: build.version_label(),
            release_version: flutter_release_version().to_owned(),
            relay_protocol: "v5".to_owned(),
            direct_protocol: "v6".to_owned(),
            license: "AGPL-3.0-or-later".to_owned(),
            source_url: "https://github.com/tianguantg/TractorBeam".to_owned(),
        },
        client_config: ClientConfigDto {
            selected_relay_id: state.selected_relay_id.clone(),
            selected_steam_id64: state.selected_steam_id64.clone(),
            mode: mode_to_dto(state.mode.unwrap_or(SessionMode::Pure)),
            transport: state.transport,
            relays: if full {
                config.map_or_else(Vec::new, |loaded| {
                    loaded.config.relays.iter().map(map_relay).collect()
                })
            } else {
                Vec::new()
            },
            accounts: if full {
                merged_accounts(snapshot, state)
            } else {
                Vec::new()
            },
            warnings: if full {
                let mut warnings = config.map_or_else(Vec::new, |loaded| loaded.warnings.clone());
                if let Some(warning) = bridge_runtime
                    .history
                    .lock()
                    .expect("history lock")
                    .warning()
                {
                    warnings.push(warning.to_owned());
                }
                warnings
            } else {
                Vec::new()
            },
        },
        session: SessionSnapshot {
            status: match runtime.status {
                SessionStatus::Idle => SessionStatusDto::Idle,
                SessionStatus::Running => SessionStatusDto::Running,
            },
            active_mode: runtime.active_session_mode.map(mode_to_dto),
            smoothness: format!("{:?}", runtime.smoothness.level).to_lowercase(),
            health: runtime
                .latest_session_health
                .as_ref()
                .map(|health| health.compact_log_line("session")),
            last_stop_reason: runtime.last_stop_reason.as_ref().map(ToString::to_string),
        },
        room: RoomSnapshot {
            active: snapshot.room_active(),
            status: if snapshot.room_active() && state.room_status != RoomStatusDto::Leaving {
                RoomStatusDto::Active
            } else {
                state.room_status
            },
            generation: state.room_generation,
            route: room_route,
            transport: room_transport,
            join_code,
            members,
            steam_identity_mismatch: runtime.steam_identity_mismatch.as_ref().map(|mismatch| {
                SteamIdentityMismatchDto {
                    room_steam_id64: mismatch.room_steam_id64.to_string(),
                    game_steam_id64: mismatch.game_steam_id64.to_string(),
                }
            }),
        },
        room_history: if full {
            let history = bridge_runtime.history.lock().expect("history lock");
            history
                .entries()
                .into_iter()
                .map(|entry| RoomHistoryEntryDto {
                    id: entry.id,
                    is_current: state.room.as_ref().is_some_and(|room| match room {
                        RoomSecret::Relay { join_code, .. } | RoomSecret::Lan { join_code, .. } => {
                            join_code == &entry.join_code
                        }
                    }),
                    join_code: entry.join_code,
                    route: match entry.route {
                        StoredRoomRoute::Relay => RoomRouteDto::Relay,
                        StoredRoomRoute::Lan => RoomRouteDto::Lan,
                    },
                })
                .collect()
        } else {
            Vec::new()
        },
        restore_history_id: full
            .then(|| {
                bridge_runtime
                    .history
                    .lock()
                    .expect("history lock")
                    .restore_entry()
                    .map(|entry| entry.id)
            })
            .flatten(),
        launch: map_launch_progress(runtime, state),
        hook: HookSnapshot {
            startup_phase: runtime.hook_startup.phase.to_string(),
            connection: runtime.hook_ipc.connection.to_string(),
            installation: runtime.hook_ipc.installation.to_string(),
            runtime_active: runtime.hook_runtime_active,
            version: runtime
                .hook_ipc
                .negotiated_major
                .zip(runtime.hook_ipc.negotiated_minor)
                .map(|(major, minor)| format!("{major}.{minor}")),
            reconnects: runtime.hook_ipc.reconnects,
            malformed_frames: runtime.hook_ipc.malformed_frames,
            last_error: runtime
                .hook_ipc
                .last_error
                .as_deref()
                .map(localize_launch_error),
            input_delay,
            input_delay_error,
        },
        counters: CountersDto {
            hook_to_relay: if full {
                runtime.counters.hook_to_relay
            } else {
                0
            },
            relay_to_hook: if full {
                runtime.counters.relay_to_hook
            } else {
                0
            },
            sent_bytes: if full { runtime.counters.sent_bytes } else { 0 },
            received_bytes: if full {
                runtime.counters.received_bytes
            } else {
                0
            },
            errors: if full { runtime.counters.errors } else { 0 },
            reconnect_dropped_packets: if full {
                runtime.counters.reconnect_dropped_packets
            } else {
                0
            },
            detached_hook_dropped_packets: if full {
                runtime.counters.detached_hook_dropped_packets
            } else {
                0
            },
            detached_relay_dropped_packets: if full {
                runtime.counters.detached_relay_dropped_packets
            } else {
                0
            },
        },
        connection_tests: if full {
            map_connection_tests(config, state, &runtime.light_ping_reports)
        } else {
            Vec::new()
        },
        logs: if full {
            runtime
                .logs
                .iter()
                .map(|entry| LogEntryDto {
                    timestamp_ms: entry.timestamp_ms,
                    level: match entry.level {
                        LogLevel::Trace => LogLevelDto::Trace,
                        LogLevel::Debug => LogLevelDto::Debug,
                        LogLevel::Info => LogLevelDto::Info,
                        LogLevel::Warn => LogLevelDto::Warn,
                        LogLevel::Error => LogLevelDto::Error,
                    },
                    message: entry.message.clone(),
                })
                .collect()
        } else {
            Vec::new()
        },
        lan_adapters: if full {
            state.lan_adapters.iter().map(map_lan_adapter).collect()
        } else {
            Vec::new()
        },
        lan_join_endpoints: if full {
            state.pending_lan.as_ref().map_or_else(Vec::new, |pending| {
                pending.endpoints.iter().map(ToString::to_string).collect()
            })
        } else {
            Vec::new()
        },
        bootstrap_error: snapshot.bootstrap_error.clone(),
        update: UpdateSnapshotDto {
            status: state.update_status,
            available_update: state.available_update.clone(),
            error: state.update_error.clone(),
            channel_url: FLUTTER_CHANNEL.release_url_prefix.trim_end_matches('/').to_owned(),
        },
    }
}

fn unavailable_snapshot(message: &str) -> AppSnapshot {
    let build = tractor_beam_core::build_info::current();
    AppSnapshot {
        profile: SnapshotProfileDto::Full,
        bootstrap: BootstrapStateDto::Failed,
        operation: None,
        can_mutate: false,
        shutdown_state: ShutdownStateDto::Unknown,
        build_info: BuildInfoDto {
            version: build.version.to_owned(),
            git_hash: build.git_hash.map(str::to_owned),
            version_label: build.version_label(),
            release_version: flutter_release_version().to_owned(),
            relay_protocol: "v5".into(),
            direct_protocol: "v6".into(),
            license: "AGPL-3.0-or-later".into(),
            source_url: "https://github.com/tianguantg/TractorBeam".into(),
        },
        client_config: ClientConfigDto {
            selected_relay_id: None,
            selected_steam_id64: None,
            mode: SessionModeDto::Unknown,
            transport: TransportSelection::Unknown,
            relays: vec![],
            accounts: vec![],
            warnings: vec![],
        },
        session: SessionSnapshot {
            status: SessionStatusDto::Unknown,
            active_mode: None,
            smoothness: "unavailable".into(),
            health: None,
            last_stop_reason: None,
        },
        room: RoomSnapshot {
            active: false,
            status: RoomStatusDto::Idle,
            generation: 0,
            route: None,
            transport: None,
            join_code: None,
            members: vec![],
            steam_identity_mismatch: None,
        },
        room_history: vec![],
        restore_history_id: None,
        launch: LaunchProgressDto {
            status: LaunchStatusDto::Idle,
            generation: 0,
            display_text: "尚未启动游戏".into(),
            error_text: None,
            terminal: false,
            success: false,
        },
        hook: HookSnapshot {
            startup_phase: "unknown".into(),
            connection: "unknown".into(),
            installation: "unknown".into(),
            runtime_active: false,
            version: None,
            reconnects: 0,
            malformed_frames: 0,
            last_error: None,
            input_delay: None,
            input_delay_error: None,
        },
        counters: CountersDto {
            hook_to_relay: 0,
            relay_to_hook: 0,
            sent_bytes: 0,
            received_bytes: 0,
            errors: 0,
            reconnect_dropped_packets: 0,
            detached_hook_dropped_packets: 0,
            detached_relay_dropped_packets: 0,
        },
        connection_tests: vec![],
        logs: vec![],
        lan_adapters: vec![],
        lan_join_endpoints: vec![],
        bootstrap_error: Some(message.to_owned()),
        update: UpdateSnapshotDto {
            status: UpdateStatusDto::Idle,
            available_update: None,
            error: None,
            channel_url: FLUTTER_CHANNEL.release_url_prefix.trim_end_matches('/').to_owned(),
        },
    }
}

fn initialize_draft(snapshot: &ApplicationSnapshot, state: &mut BridgeState) {
    if state.initialized_from_config {
        return;
    }
    let Some(config) = snapshot.loaded_config.as_ref() else {
        return;
    };
    state
        .selected_relay_id
        .clone_from(&config.config.selected_relay);
    state
        .selected_steam_id64
        .clone_from(&config.config.selected_steam_id64);
    state
        .manual_steam_accounts
        .clone_from(&config.config.manual_steam_accounts);
    state.mode = Some(config.config.default_mode);
    state.transport = config
        .config
        .default_transport
        .map_or(TransportSelection::RelayDefault, transport_to_dto);
    state.initialized_from_config = true;
}

fn normalize_selections(snapshot: &ApplicationSnapshot, state: &mut BridgeState) {
    if let Some(config) = snapshot.loaded_config.as_ref() {
        let relay_is_valid = state.selected_relay_id.as_ref().is_some_and(|selected| {
            config
                .config
                .relays
                .iter()
                .any(|relay| relay.id == *selected)
        });
        if !relay_is_valid {
            state.selected_relay_id = config.config.relays.first().map(|relay| relay.id.clone());
        }
    }

    let account_is_valid = state.selected_steam_id64.as_ref().is_some_and(|selected| {
        snapshot
            .runtime
            .detected_accounts
            .iter()
            .any(|account| account.steam_id64 == *selected)
            || state
                .manual_steam_accounts
                .iter()
                .any(|account| account.steam_id64 == *selected)
    });
    if !account_is_valid {
        state.selected_steam_id64 = snapshot
            .runtime
            .detected_accounts
            .first()
            .map(|account| account.steam_id64.clone())
            .or_else(|| {
                state
                    .manual_steam_accounts
                    .first()
                    .map(|account| account.steam_id64.clone())
            });
    }
}

fn snapshot_and_draft(runtime: &BridgeRuntime) -> (ApplicationSnapshot, BridgeState) {
    let snapshot = runtime
        .application
        .lock()
        .expect("application lock")
        .snapshot();
    let state = runtime.state.lock().expect("state lock");
    (
        snapshot,
        BridgeState {
            snapshot_profile: state.snapshot_profile,
            initialized_from_config: state.initialized_from_config,
            selected_relay_id: state.selected_relay_id.clone(),
            selected_steam_id64: state.selected_steam_id64.clone(),
            manual_steam_accounts: state.manual_steam_accounts.clone(),
            mode: state.mode,
            transport: state.transport,
            room: state.room.as_ref().map(clone_room),
            pending_room: state.pending_room.as_ref().map(clone_room),
            room_status: state.room_status,
            room_generation: state.room_generation,
            lan_adapters: state.lan_adapters.clone(),
            pending_lan: state.pending_lan.as_ref().map(|p| PendingLanJoin {
                invitation: p.invitation.clone(),
                endpoints: p.endpoints.clone(),
                join_code: p.join_code.clone(),
            }),
            pending_relay_op: state.pending_relay_op.clone(),
            launch_generation: state.launch_generation,
            launch_pending: state.launch_pending,
            launch_cancel_requested: state.launch_cancel_requested,
            launch_cancelled: state.launch_cancelled,
            launch_error: state.launch_error.clone(),
            launch_started_at: state.launch_started_at,
            update_status: state.update_status,
            available_update: state.available_update.clone(),
            update_error: state.update_error.clone(),
        },
    )
}

fn clone_room(room: &RoomSecret) -> RoomSecret {
    match room {
        RoomSecret::Relay { route, join_code } => RoomSecret::Relay {
            route: route.clone(),
            join_code: join_code.clone(),
        },
        RoomSecret::Lan {
            credential,
            join_code,
        } => RoomSecret::Lan {
            credential: *credential,
            join_code: join_code.clone(),
        },
    }
}

fn submit(action: impl FnOnce(&ApplicationHandle, &BridgeRuntime) -> bool) -> CommandReceipt {
    let Some(runtime) = APPLICATION.get() else {
        return not_initialized();
    };
    let application = runtime.application.lock().expect("application lock");
    receipt(action(&application, runtime))
}

fn mutate_draft(
    action: impl FnOnce(&mut BridgeState),
) -> Result<CommandReceipt, Box<CommandReceipt>> {
    let Some(runtime) = APPLICATION.get() else {
        return Err(Box::new(not_initialized()));
    };
    action(&mut runtime.state.lock().expect("state lock"));
    publish_update(runtime);
    Ok(accepted())
}

fn persist_selection() -> CommandReceipt {
    let Some(runtime) = APPLICATION.get() else {
        return not_initialized();
    };
    let selection = {
        let state = runtime.state.lock().expect("state lock");
        ClientConfigSelection {
            selected_relay: state.selected_relay_id.clone(),
            selected_steam_id64: state.selected_steam_id64.clone(),
        }
    };
    runtime
        .application
        .lock()
        .expect("application lock")
        .persist_selection(selection);
    accepted()
}

fn save_relay(change: RelayCatalogChange) -> CommandReceipt {
    submit(move |app, _| app.save_relay_catalog(change))
}

fn persist_preferences() -> CommandReceipt {
    let Some(runtime) = APPLICATION.get() else {
        return not_initialized();
    };
    let (snapshot, state) = snapshot_and_draft(runtime);
    let current = snapshot.loaded_config.as_ref().map(|loaded| &loaded.config);
    let default_transport = transport_from_dto(state.transport);
    let preferences = ClientConfigPreferences {
        default_transport,
        default_mode: state.mode.unwrap_or(SessionMode::Pure),
        session_health_enabled: current.is_none_or(|config| config.session_health.enabled),
    };
    receipt(
        runtime
            .application
            .lock()
            .expect("application lock")
            .save_preferences(preferences),
    )
}

fn relay_input(relay: RelayDraft) -> Result<RelayProfileInput, Box<CommandReceipt>> {
    if relay.port == 0 || relay.port > u32::from(u16::MAX) {
        return Err(Box::new(rejected(
            "invalid_relay_port",
            "Relay 端口必须为 1–65535",
        )));
    }
    let Some(default_transport) = transport_from_dto(relay.default_transport) else {
        return Err(Box::new(rejected(
            "unknown_enum",
            "默认协议必须为 TCP 或 UDP",
        )));
    };
    Ok(RelayProfileInput {
        name: relay.name,
        endpoint: RelayEndpoint::new(
            relay.host,
            u16::try_from(relay.port).expect("port range validated above"),
        ),
        supports_udp: relay.supports_udp,
        supports_tcp: relay.supports_tcp,
        default_transport,
    })
}

fn selected_identity_and_relay<'a>(
    snapshot: &'a ApplicationSnapshot,
    state: &BridgeState,
) -> Result<(&'a tractor_beam_core::RelayPreset, String, String), ()> {
    let (steam, name) = selected_identity(snapshot, state)?;
    let config = snapshot.loaded_config.as_ref().ok_or(())?;
    let relay = config
        .config
        .relays
        .iter()
        .find(|relay| Some(relay.id.as_str()) == state.selected_relay_id.as_deref())
        .ok_or(())?;
    Ok((relay, steam.to_string(), name))
}

fn selected_identity(
    snapshot: &ApplicationSnapshot,
    state: &BridgeState,
) -> Result<(u64, String), ()> {
    let id = state.selected_steam_id64.as_deref().ok_or(())?;
    let numeric = id.parse::<u64>().map_err(|_| ())?;
    if numeric == 0 {
        return Err(());
    }
    let name = account_display_name(snapshot, state, id).unwrap_or_else(|| id.to_owned());
    Ok((numeric, name))
}

fn build_session_config(
    snapshot: &ApplicationSnapshot,
    state: &BridgeState,
) -> Result<(SessionConfig, ClientConfigSelection), Box<CommandReceipt>> {
    let Ok((steam_id, display_name)) = selected_identity(snapshot, state) else {
        return Err(Box::new(rejected(
            "steam_account_missing",
            "请先选择 Steam 账号",
        )));
    };
    let mode = state.mode.unwrap_or(SessionMode::Pure);
    let health = snapshot
        .loaded_config
        .as_ref()
        .map_or_else(Default::default, |c| c.config.session_health);
    let route = match state.room.as_ref() {
        Some(RoomSecret::Relay { route, .. }) => SessionRouteConfig::ExternalRelay(route.clone()),
        Some(RoomSecret::Lan { credential, .. }) => {
            SessionRouteConfig::LanDirect(LanDirectConfig {
                session_credential: *credential,
                room: None,
            })
        }
        None => return Err(Box::new(rejected("room_missing", "尚未加入任何房间"))),
    };
    let selection = ClientConfigSelection {
        selected_relay: state.selected_relay_id.clone(),
        selected_steam_id64: state.selected_steam_id64.clone(),
    };
    Ok((
        SessionConfig {
            route,
            mode,
            steam_id64: steam_id.to_string(),
            display_name,
            session_health: health,
        },
        selection,
    ))
}

fn account_display_name(
    snapshot: &ApplicationSnapshot,
    state: &BridgeState,
    steam_id64: &str,
) -> Option<String> {
    state
        .manual_steam_accounts
        .iter()
        .find(|account| account.steam_id64 == steam_id64)
        .map(|account| account.display_name.clone())
        .or_else(|| {
            snapshot
                .runtime
                .detected_accounts
                .iter()
                .find(|account| account.steam_id64 == steam_id64)
                .map(|account| account.display_name.clone())
        })
}

fn merged_accounts(snapshot: &ApplicationSnapshot, state: &BridgeState) -> Vec<SteamAccountDto> {
    let mut accounts = snapshot
        .runtime
        .detected_accounts
        .iter()
        .map(|account| SteamAccountDto {
            steam_id64: account.steam_id64.clone(),
            display_name: account.display_name.clone(),
            most_recent: account.most_recent,
            is_manual: false,
        })
        .collect::<Vec<_>>();
    for manual in &state.manual_steam_accounts {
        if let Some(existing) = accounts
            .iter_mut()
            .find(|account| account.steam_id64 == manual.steam_id64)
        {
            existing.display_name.clone_from(&manual.display_name);
            existing.is_manual = true;
        } else {
            accounts.push(SteamAccountDto {
                steam_id64: manual.steam_id64.clone(),
                display_name: manual.display_name.clone(),
                most_recent: false,
                is_manual: true,
            });
        }
    }
    accounts
}

fn effective_transport(
    state: &BridgeState,
    relay: &tractor_beam_core::RelayPreset,
) -> TransportChoice {
    match state.transport {
        TransportSelection::Udp => {
            if relay.supports_udp {
                TransportChoice::Udp
            } else {
                relay.preferred_transport(TransportChoice::Tcp)
            }
        }
        TransportSelection::Tcp => {
            if relay.supports_tcp {
                TransportChoice::Tcp
            } else {
                relay.preferred_transport(TransportChoice::Udp)
            }
        }
        TransportSelection::RelayDefault | TransportSelection::Unknown => {
            relay.preferred_transport(TransportChoice::Tcp)
        }
    }
}

fn same_physical_light_ping_target(left: &LightPingTarget, right: &LightPingTarget) -> bool {
    left.endpoint.port == right.endpoint.port
        && left
            .endpoint
            .host
            .trim_end_matches('.')
            .eq_ignore_ascii_case(right.endpoint.host.trim_end_matches('.'))
        && left.transport == right.transport
}

fn deduplicate_light_ping_targets(targets: Vec<LightPingTarget>) -> Vec<LightPingTarget> {
    let mut unique = Vec::with_capacity(targets.len());
    for target in targets {
        if !unique
            .iter()
            .any(|existing| same_physical_light_ping_target(existing, &target))
        {
            unique.push(target);
        }
    }
    unique
}

fn map_connection_tests(
    config: Option<&tractor_beam_core::LoadedClientConfig>,
    state: &BridgeState,
    reports: &[LightPingReport],
) -> Vec<ConnectionTestDto> {
    let Some(config) = config else {
        return reports.iter().map(map_connection_test_report).collect();
    };
    config
        .config
        .relays
        .iter()
        .filter_map(|relay| {
            let logical_target = LightPingTarget {
                relay_id: Some(relay.id.clone()),
                relay_name: Some(relay.name.clone()),
                endpoint: relay.endpoint.clone(),
                transport: effective_transport(state, relay),
            };
            reports
                .iter()
                .find(|report| same_physical_light_ping_target(&logical_target, &report.target))
                .map(|report| {
                    let mut mapped = map_connection_test_report(report);
                    mapped.relay_id = logical_target.relay_id;
                    mapped.relay_name = logical_target.relay_name;
                    mapped
                })
        })
        .collect()
}

fn map_connection_test_report(report: &LightPingReport) -> ConnectionTestDto {
    ConnectionTestDto {
        relay_id: report.target.relay_id.clone(),
        relay_name: report.target.relay_name.clone(),
        endpoint: report.target.endpoint.to_string(),
        transport: transport_to_dto(report.target.transport),
        sent: u32::from(report.sent),
        received: u32::from(report.received),
        median_rtt_ms: report.median_rtt_ms.map(saturating_u64),
        failure_reason: report.failure_reason.as_deref().map(localize_network_error),
    }
}

fn relay_transport_for_endpoint(
    snapshot: &ApplicationSnapshot,
    state: &BridgeState,
    relay_id: Option<&str>,
) -> TransportChoice {
    snapshot
        .loaded_config
        .as_ref()
        .and_then(|loaded| {
            loaded
                .config
                .relays
                .iter()
                .find(|relay| Some(relay.id.as_str()) == relay_id)
        })
        .map_or_else(
            || transport_from_dto(state.transport).unwrap_or(TransportChoice::Tcp),
            |relay| effective_transport(state, relay),
        )
}

fn map_launch_progress(
    runtime: &tractor_beam_core::RuntimeState,
    state: &BridgeState,
) -> LaunchProgressDto {
    if state.launch_cancel_requested {
        return LaunchProgressDto {
            status: LaunchStatusDto::Cancelling,
            generation: state.launch_generation,
            display_text: "正在停止 TractorBeam 启动流程".to_owned(),
            error_text: None,
            terminal: false,
            success: false,
        };
    }
    if state.launch_cancelled {
        return LaunchProgressDto {
            status: LaunchStatusDto::Cancelled,
            generation: state.launch_generation,
            display_text: "游戏启动已取消".to_owned(),
            error_text: None,
            terminal: true,
            success: false,
        };
    }
    if let Some(error) = &state.launch_error {
        return LaunchProgressDto {
            status: LaunchStatusDto::Failed,
            generation: state.launch_generation,
            display_text: "游戏启动失败".to_owned(),
            error_text: Some(error.clone()),
            terminal: true,
            success: false,
        };
    }
    let (status, text, terminal, success) = match runtime.hook_startup.phase {
        HookStartupPhase::NotStarted if state.launch_pending => {
            (LaunchStatusDto::Starting, "正在准备启动游戏", false, false)
        }
        HookStartupPhase::NotStarted => (LaunchStatusDto::Idle, "尚未启动游戏", false, false),
        HookStartupPhase::Configured => (LaunchStatusDto::Starting, "启动参数已配置", false, false),
        HookStartupPhase::WaitingForIsaac => (
            LaunchStatusDto::WaitingForGame,
            "正在等待游戏进程",
            false,
            false,
        ),
        HookStartupPhase::Injecting => (
            LaunchStatusDto::Injecting,
            "已发现游戏，正在注入 Hook",
            false,
            false,
        ),
        HookStartupPhase::WaitingForHookEndpoint | HookStartupPhase::EndpointReady => (
            LaunchStatusDto::WaitingForHook,
            "注入完成，正在连接 Hook",
            false,
            false,
        ),
        HookStartupPhase::Ready => (LaunchStatusDto::Ready, "游戏与 Hook 已就绪", true, true),
        HookStartupPhase::Failed => (LaunchStatusDto::Failed, "游戏启动失败", true, false),
        HookStartupPhase::Cancelled => (LaunchStatusDto::Cancelled, "游戏启动已取消", true, false),
    };
    LaunchProgressDto {
        status,
        generation: state.launch_generation,
        display_text: text.to_owned(),
        error_text: if status == LaunchStatusDto::Failed {
            Some(localize_launch_error(
                runtime
                    .hook_startup
                    .message
                    .as_deref()
                    .or(runtime.hook_ipc.last_error.as_deref())
                    .unwrap_or("unknown launch failure"),
            ))
        } else {
            None
        },
        terminal,
        success,
    }
}

fn enforce_launch_timeout(
    bridge_runtime: &BridgeRuntime,
    snapshot: &ApplicationSnapshot,
    state: &mut BridgeState,
    events: &mut Vec<AppEvent>,
) {
    if matches!(
        snapshot.runtime.hook_startup.phase,
        HookStartupPhase::Ready | HookStartupPhase::Failed | HookStartupPhase::Cancelled
    ) {
        state.launch_pending = false;
        state.launch_started_at = None;
        return;
    }
    if !launch_timeout_elapsed(state.launch_started_at) {
        return;
    }

    state.launch_pending = false;
    state.launch_cancel_requested = false;
    state.launch_cancelled = false;
    state.launch_started_at = None;
    state.launch_error =
        Some("启动等待超过 120 秒，本次启动已停止。请确认游戏和 Steam 状态后重试。".to_owned());
    let _ = bridge_runtime
        .application
        .lock()
        .expect("application lock")
        .stop_session();
    events.push(event(
        "launch_timeout",
        false,
        "启动游戏超时，本次启动已停止",
        None,
    ));
}

fn launch_timeout_elapsed(started_at: Option<Instant>) -> bool {
    started_at.is_some_and(|started| started.elapsed() >= LAUNCH_TIMEOUT)
}

fn localize_network_error(message: &str) -> String {
    let normalized = message.to_ascii_lowercase();
    if message.contains("不知道这样的主机")
        || normalized.contains("no such host is known")
        || normalized.contains("name or service not known")
        || normalized.contains("failed to lookup address information")
        || normalized.contains("nodename nor servname provided")
    {
        return "无法解析 Relay 服务器地址，请检查主机名是否正确以及 DNS 和网络是否可用。"
            .to_owned();
    }
    if message.contains("由于目标计算机积极拒绝")
        || normalized.contains("connection refused")
        || normalized.contains("actively refused")
    {
        return "Relay 服务器拒绝连接，请检查地址、端口和服务器运行状态。".to_owned();
    }
    if normalized.contains("timed out")
        || normalized.contains("timeout")
        || message.contains("超时")
    {
        return "连接 Relay 服务器超时，请检查网络、防火墙或服务器状态。".to_owned();
    }
    if normalized.contains("network is unreachable")
        || normalized.contains("no route to host")
        || message.contains("网络不可达")
    {
        return "当前网络无法到达 Relay 服务器，请检查网络连接和路由设置。".to_owned();
    }
    if normalized.contains("connection reset") || message.contains("连接被重置") {
        return "Relay 连接被中断，请检查网络或稍后重试。".to_owned();
    }
    if normalized == "no pongs received" || normalized.contains("ping timed out") {
        return "Relay 服务器未响应测速请求，请检查节点状态、网络或防火墙。".to_owned();
    }
    let trimmed = message.trim();
    if trimmed.is_empty() {
        "无法连接到 Relay 服务器，请检查节点配置和网络状态。".to_owned()
    } else {
        format!("无法连接到 Relay 服务器：{trimmed}")
    }
}

fn is_udp_fallback_error(message: &str) -> bool {
    let normalized = message.to_ascii_lowercase();
    normalized.contains("timed out")
        || normalized.contains("timeout")
        || normalized.contains("no pongs received")
        || normalized.contains("ping timed out")
        || message.contains("超时")
}

fn localize_launch_error(message: &str) -> String {
    let normalized = message.to_ascii_lowercase();
    if normalized.contains("already running") || normalized.contains("gameplay is already running")
    {
        return "以撒游戏已在运行中。请先完全退出以撒，然后重新点击启动游戏。".to_owned();
    }
    if normalized.contains("already loaded") {
        return "检测到上一次的 Hook 仍留在游戏中。请完全退出游戏后再试。".to_owned();
    }
    if normalized.contains("cannot change while isaac is running")
        || normalized.contains("switching between fallback and pure mode")
    {
        return "以撒运行期间无法更改工作模式，请完全退出游戏后重试。".to_owned();
    }
    if normalized.contains("is still starting") {
        return "游戏启动流程正在进行中，请稍候。".to_owned();
    }
    if normalized.contains("access denied")
        || normalized.contains("permission denied")
        || message.contains("拒绝访问")
    {
        return "注入权限不足。请关闭可能阻止注入的程序，或尝试以管理员身份运行。".to_owned();
    }
    if normalized.contains("process was not found")
        || normalized.contains("process not found")
        || normalized.contains("could not find process")
    {
        return "未发现以撒游戏进程，请确认游戏是否已正常启动。".to_owned();
    }
    if normalized.contains("artifact")
        || normalized.contains("paths are required")
        || normalized.contains("dll was not found")
        || normalized.contains("helper was not found")
    {
        return "缺少启动所需的注入组件，请检查程序文件是否完整。".to_owned();
    }
    if normalized.contains("launch parameter") {
        return "无法准备 Hook 启动参数，请检查程序目录的写入权限。".to_owned();
    }
    if normalized.contains("bind failed") {
        return "无法建立本地 Hook 通信端点，请关闭旧的游戏进程后重试。".to_owned();
    }
    if normalized.contains("steam api imports") {
        return "Hook 无法接管 Steam API。请完全退出游戏后重试。".to_owned();
    }
    if normalized.contains("networking hooks") {
        return "Hook 无法安装网络功能。请完全退出游戏后重试。".to_owned();
    }
    if normalized.contains("timed out")
        || normalized.contains("timeout")
        || normalized.contains("did not finish")
    {
        return "等待游戏或 Hook 就绪超时，请确认游戏已正常启动后重试。".to_owned();
    }
    if normalized.contains("admin permission was cancelled") {
        return "已取消管理员提权授权，无法完成 Hook 注入。".to_owned();
    }
    if normalized.contains("cancel") {
        return "游戏启动已取消。".to_owned();
    }
    if normalized.contains("steam launch")
        || (normalized.contains("launch") && normalized.contains("steam"))
    {
        return "无法通过 Steam 启动游戏，请确认 Steam 正在运行。".to_owned();
    }
    if normalized.contains("unsupported platform") {
        return "当前操作系统平台暂不支持原生 Hook 注入。".to_owned();
    }
    if normalized.contains("cannot be reattached") || normalized.contains("cannot be detached") {
        return "当前游戏运行时无法重新附加或分离，请完全退出游戏后重试。".to_owned();
    }
    if normalized.contains("broken pipe") || normalized.contains("hook runtime has stopped") {
        return "Hook 运行时已终止，请重新启动游戏。".to_owned();
    }
    if normalized.contains("the system cannot find the file specified")
        || message.contains("系统找不到指定的文件")
    {
        return "系统找不到指定的文件，请检查游戏或注入组件完整性。".to_owned();
    }
    if normalized.contains("injection failed at open isaac process") {
        return "Hook 注入失败：无法打开以撒进程（请尝试以管理员身份运行或检查杀毒软件拦截）。"
            .to_owned();
    }
    if normalized.contains("injection failed at create remote thread") {
        return "Hook 注入失败：无法在游戏中创建注入线程（可能被安全软件拦截）。".to_owned();
    }
    if normalized.contains("injection failed at allocate remote memory") {
        return "Hook 注入失败：无法为以撒进程分配内存。".to_owned();
    }
    if normalized.contains("injection failed at write dll path") {
        return "Hook 注入失败：无法向游戏写入注入路径。".to_owned();
    }
    if normalized.contains("injection failed at") {
        return "Hook 注入以撒进程失败，请尝试以管理员身份运行或检查杀毒软件拦截。".to_owned();
    }
    let trimmed = message.trim();
    if trimmed.is_empty() || trimmed.eq_ignore_ascii_case("unknown launch failure") {
        "游戏未能正常启动，未获取到具体错误信息。".to_owned()
    } else {
        trimmed.to_owned()
    }
}

fn localize_input_delay_error(error: &InputDelayError, writing: bool) -> String {
    let action = if writing { "写入" } else { "读取" };
    match error {
        InputDelayError::SessionNotRunning => {
            format!("游戏尚未运行，无法{action}输入延迟。")
        }
        InputDelayError::UnsupportedMode => {
            "当前工作模式不支持输入延迟控制，请使用 Fallback 或 Pure 模式。".to_owned()
        }
        InputDelayError::HookNotReady => "Hook 尚未就绪，请稍后再试。".to_owned(),
        InputDelayError::Hook(_) => {
            format!("Hook 拒绝了输入延迟{action}请求，请稍后重试。")
        }
        InputDelayError::Io(error) if error.kind() == std::io::ErrorKind::TimedOut => {
            if writing {
                "写入输入延迟超时，请稍后在设置页重试。".to_owned()
            } else {
                "游戏已启动，但读取输入延迟超时；可稍后在设置页重试。".to_owned()
            }
        }
        InputDelayError::Io(error) if error.kind() == std::io::ErrorKind::WouldBlock => {
            "Hook 正忙，请稍后重试输入延迟操作。".to_owned()
        }
        InputDelayError::Io(_) => format!("无法{action}输入延迟，请稍后重试。"),
    }
}

fn map_relay(relay: &tractor_beam_core::RelayPreset) -> RelayDto {
    RelayDto {
        id: relay.id.clone(),
        name: relay.name.clone(),
        host: relay.endpoint.host.clone(),
        port: u32::from(relay.endpoint.port),
        supports_udp: relay.supports_udp,
        supports_tcp: relay.supports_tcp,
        default_transport: relay
            .default_transport
            .map_or(TransportSelection::RelayDefault, transport_to_dto),
    }
}
fn map_lan_adapter(adapter: &LanAdapter) -> LanAdapterDto {
    LanAdapterDto {
        id: adapter.adapter_id.clone(),
        name: adapter.name.clone(),
        interface_index: adapter.interface_index,
        addresses: adapter
            .addresses
            .iter()
            .map(|address| address.address.to_string())
            .collect(),
        recommended: adapter.is_recommended(),
    }
}
fn mode_from_dto(mode: SessionModeDto) -> Option<SessionMode> {
    match mode {
        SessionModeDto::Official => Some(SessionMode::Official),
        SessionModeDto::Fallback => Some(SessionMode::Fallback),
        SessionModeDto::Pure => Some(SessionMode::Pure),
        SessionModeDto::Unknown => None,
    }
}
fn mode_to_dto(mode: SessionMode) -> SessionModeDto {
    match mode {
        SessionMode::Official => SessionModeDto::Official,
        SessionMode::Fallback => SessionModeDto::Fallback,
        SessionMode::Pure => SessionModeDto::Pure,
    }
}
fn transport_from_dto(value: TransportSelection) -> Option<TransportChoice> {
    match value {
        TransportSelection::Udp => Some(TransportChoice::Udp),
        TransportSelection::Tcp => Some(TransportChoice::Tcp),
        TransportSelection::RelayDefault | TransportSelection::Unknown => None,
    }
}
fn transport_to_dto(value: TransportChoice) -> TransportSelection {
    match value {
        TransportChoice::Udp => TransportSelection::Udp,
        TransportChoice::Tcp => TransportSelection::Tcp,
    }
}
fn operation_name(value: ApplicationOperation) -> String {
    format!("{value:?}").to_lowercase()
}
fn duration_ms(value: std::time::Duration) -> u64 {
    saturating_u64(value.as_millis())
}
fn saturating_u64(value: u128) -> u64 {
    u64::try_from(value).unwrap_or(u64::MAX)
}

fn accepted() -> CommandReceipt {
    CommandReceipt {
        accepted: true,
        rejection: None,
    }
}
fn receipt(value: bool) -> CommandReceipt {
    if value {
        accepted()
    } else {
        rejected("queue_busy", "命令队列繁忙，请稍后重试")
    }
}
fn not_initialized() -> CommandReceipt {
    rejected("not_initialized", "应用尚未初始化")
}
fn rejected(code: &str, text: &str) -> CommandReceipt {
    CommandReceipt {
        accepted: false,
        rejection: Some(CommandRejection {
            code: code.to_owned(),
            display_text: text.to_owned(),
            message: LocalizedMessageDto {
                key: format!("rejection.{code}"),
                args: Vec::new(),
                fallback_zh: text.to_owned(),
            },
        }),
    }
}
fn event(code: &str, success: bool, text: &str, value: Option<String>) -> AppEvent {
    AppEvent {
        code: code.to_owned(),
        success,
        display_text: text.to_owned(),
        value,
        message: LocalizedMessageDto {
            key: format!(
                "event.{code}.{}",
                if success { "success" } else { "failure" }
            ),
            args: Vec::new(),
            fallback_zh: text.to_owned(),
        },
    }
}
fn result_event<T: std::fmt::Display>(code: &str, value: Result<String, T>) -> AppEvent {
    match value {
        Ok(text) => event(code, true, &text, None),
        Err(error) => event(code, false, &error.to_string(), None),
    }
}
fn path_event(code: &str, value: Result<std::path::PathBuf, String>) -> AppEvent {
    match value {
        Ok(path) => event(code, true, "操作已完成", Some(path.display().to_string())),
        Err(error) => event(code, false, &error, None),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn duplicate_relay_targets_share_one_physical_probe() {
        let endpoint = RelayEndpoint::new("Relay.Example.Test.", 25910);
        let targets = vec![
            LightPingTarget {
                relay_id: Some("first".to_owned()),
                relay_name: Some("First".to_owned()),
                endpoint: endpoint.clone(),
                transport: TransportChoice::Udp,
            },
            LightPingTarget {
                relay_id: Some("second".to_owned()),
                relay_name: Some("Second".to_owned()),
                endpoint: RelayEndpoint::new("relay.example.test", 25910),
                transport: TransportChoice::Udp,
            },
            LightPingTarget {
                relay_id: Some("tcp".to_owned()),
                relay_name: Some("TCP".to_owned()),
                endpoint,
                transport: TransportChoice::Tcp,
            },
        ];

        let unique = deduplicate_light_ping_targets(targets);
        assert_eq!(unique.len(), 2);
        assert_eq!(unique[0].relay_id.as_deref(), Some("first"));
        assert_eq!(unique[0].transport, TransportChoice::Udp);
        assert_eq!(unique[1].transport, TransportChoice::Tcp);
    }

    #[test]
    fn one_physical_report_is_fanned_out_to_duplicate_relay_ids() {
        let endpoint = RelayEndpoint::new("relay.example.test", 25910);
        let relays = ["first", "second"]
            .into_iter()
            .map(|id| tractor_beam_core::RelayPreset {
                id: id.to_owned(),
                name: id.to_uppercase(),
                endpoint: endpoint.clone(),
                supports_udp: true,
                supports_tcp: true,
                default_transport: Some(TransportChoice::Udp),
            })
            .collect();
        let config = tractor_beam_core::LoadedClientConfig {
            config: tractor_beam_core::ClientConfig {
                relays,
                ..tractor_beam_core::ClientConfig::default()
            },
            ..tractor_beam_core::LoadedClientConfig::default()
        };
        let reports = vec![LightPingReport {
            target: LightPingTarget {
                relay_id: Some("first".to_owned()),
                relay_name: Some("FIRST".to_owned()),
                endpoint,
                transport: TransportChoice::Udp,
            },
            sent: 5,
            received: 5,
            median_rtt_ms: Some(27),
            failure_reason: None,
        }];

        let state = BridgeState {
            transport: TransportSelection::Udp,
            ..BridgeState::default()
        };
        let mapped = map_connection_tests(Some(&config), &state, &reports);
        assert_eq!(mapped.len(), 2);
        assert_eq!(mapped[0].relay_id.as_deref(), Some("first"));
        assert_eq!(mapped[1].relay_id.as_deref(), Some("second"));
        assert!(mapped.iter().all(|report| report.median_rtt_ms == Some(27)));
    }

    #[test]
    fn unknown_enums_are_rejected_conservatively() {
        assert_eq!(mode_from_dto(SessionModeDto::Unknown), None);
        assert_eq!(transport_from_dto(TransportSelection::Unknown), None);
        assert_eq!(transport_from_dto(TransportSelection::RelayDefault), None);
    }

    #[test]
    fn relay_ports_have_stable_validation_errors() {
        let result = relay_input(RelayDraft {
            name: "invalid".to_owned(),
            host: "localhost".to_owned(),
            port: 0,
            supports_udp: true,
            supports_tcp: true,
            default_transport: TransportSelection::Tcp,
        });
        let error = result.expect_err("zero must not be accepted as a relay port");
        assert!(!error.accepted);
        assert_eq!(
            error.rejection.expect("rejection details").code,
            "invalid_relay_port"
        );
    }

    #[test]
    fn launch_progress_is_typed_and_only_terminal_after_result() {
        let mut runtime = tractor_beam_core::RuntimeState::default();
        let mut state = BridgeState::default();
        assert_eq!(
            map_launch_progress(&runtime, &state).status,
            LaunchStatusDto::Idle
        );

        state.launch_pending = true;
        state.launch_generation = 3;
        let starting = map_launch_progress(&runtime, &state);
        assert_eq!(starting.status, LaunchStatusDto::Starting);
        assert!(!starting.terminal);

        state.launch_cancel_requested = true;
        let cancelling = map_launch_progress(&runtime, &state);
        assert_eq!(cancelling.status, LaunchStatusDto::Cancelling);
        assert_eq!(cancelling.generation, 3);
        assert!(!cancelling.terminal);
        assert!(cancelling.error_text.is_none());

        state.launch_cancel_requested = false;
        state.launch_cancelled = true;
        let cancelled = map_launch_progress(&runtime, &state);
        assert_eq!(cancelled.status, LaunchStatusDto::Cancelled);
        assert!(cancelled.terminal);
        assert!(!cancelled.success);
        assert!(cancelled.error_text.is_none());

        state.launch_cancelled = false;

        runtime.hook_startup.phase = HookStartupPhase::Ready;
        let ready = map_launch_progress(&runtime, &state);
        assert_eq!(ready.status, LaunchStatusDto::Ready);
        assert_eq!(ready.generation, 3);
        assert!(ready.terminal);
        assert!(ready.success);

        runtime.hook_startup.phase = HookStartupPhase::Failed;
        let failed = map_launch_progress(&runtime, &state);
        assert_eq!(failed.status, LaunchStatusDto::Failed);
        assert!(failed.terminal);
        assert!(!failed.success);
    }

    #[test]
    fn launch_timeout_is_bounded_and_launch_errors_are_localized() {
        assert!(!launch_timeout_elapsed(None));
        assert!(!launch_timeout_elapsed(Some(Instant::now())));
        let expired = Instant::now()
            .checked_sub(LAUNCH_TIMEOUT + Duration::from_millis(1))
            .expect("the test clock supports a two-minute lookback");
        assert!(launch_timeout_elapsed(Some(expired)));

        assert_eq!(
            localize_launch_error("Native Hook local IPC connection timed out"),
            "等待游戏或 Hook 就绪超时，请确认游戏已正常启动后重试。"
        );
        assert_eq!(
            localize_launch_error(
                "Isaac is already running. Fully exit Isaac, then click Launch Game again."
            ),
            "以撒游戏已在运行中。请先完全退出以撒，然后重新点击启动游戏。"
        );
        assert_eq!(
            localize_launch_error("Gameplay is already running"),
            "以撒游戏已在运行中。请先完全退出以撒，然后重新点击启动游戏。"
        );
        assert_eq!(
            localize_launch_error("Admin permission was cancelled"),
            "已取消管理员提权授权，无法完成 Hook 注入。"
        );
        assert_eq!(
            localize_launch_error(
                "Native Hook injection failed at create remote thread: access denied"
            ),
            "注入权限不足。请关闭可能阻止注入的程序，或尝试以管理员身份运行。"
        );
        assert_eq!(
            localize_launch_error("Native Hook exploded"),
            "Native Hook exploded"
        );
        assert_eq!(
            localize_launch_error("   "),
            "游戏未能正常启动，未获取到具体错误信息。"
        );
    }

    #[test]
    fn tcp_fallback_is_only_suggested_for_udp_timeout_signals() {
        assert!(is_udp_fallback_error(
            "connect failed: connection timed out"
        ));
        assert!(is_udp_fallback_error("no pongs received"));
        assert!(!is_udp_fallback_error("no such host is known"));
        assert!(!is_udp_fallback_error("connection refused"));
        assert!(!is_udp_fallback_error("invalid join code"));
    }

    #[test]
    fn input_delay_errors_are_localized_without_exposing_ipc_details() {
        let timeout = InputDelayError::Io(std::io::Error::new(
            std::io::ErrorKind::TimedOut,
            "local IPC Input Delay response timed out: timed out waiting on channel",
        ));
        let display = localize_input_delay_error(&timeout, false);
        assert_eq!(
            display,
            "游戏已启动，但读取输入延迟超时；可稍后在设置页重试。"
        );
        assert!(!display.to_ascii_lowercase().contains("ipc"));
        assert_eq!(
            localize_input_delay_error(&InputDelayError::HookNotReady, false),
            "Hook 尚未就绪，请稍后再试。"
        );
    }

    #[test]
    fn relay_network_errors_are_localized_actionably() {
        assert_eq!(
            localize_network_error("不知道这样的主机。 (os error 11001)"),
            "无法解析 Relay 服务器地址，请检查主机名是否正确以及 DNS 和网络是否可用。"
        );
        assert_eq!(
            localize_network_error("connect failed: connection timed out"),
            "连接 Relay 服务器超时，请检查网络、防火墙或服务器状态。"
        );
        assert_eq!(
            localize_network_error("connect failed: connection refused"),
            "Relay 服务器拒绝连接，请检查地址、端口和服务器运行状态。"
        );
    }

    #[test]
    fn unavailable_snapshot_is_safe_and_has_build_identity() {
        let snapshot = unavailable_snapshot("unavailable");
        assert!(!snapshot.can_mutate);
        assert!(!snapshot.room.active);
        assert!(snapshot.room.join_code.is_none());
        assert_eq!(snapshot.build_info.license, "AGPL-3.0-or-later");
        assert_eq!(
            snapshot.build_info.source_url,
            "https://github.com/tianguantg/TractorBeam"
        );
        assert_eq!(
            snapshot.build_info.release_version,
            DEFAULT_FLUTTER_RELEASE_VERSION
        );
        assert_eq!(snapshot.update.status, UpdateStatusDto::Idle);
        assert_eq!(
            snapshot.update.channel_url,
            "https://github.com/tianguantg/TractorBeam/releases"
        );
        let exposed = format!("{snapshot:?}");
        for forbidden in [
            "session_credential",
            "resume_key",
            "connection_id",
            "path_token",
        ] {
            assert!(!exposed.contains(forbidden));
        }
    }

    #[test]
    fn lightweight_snapshot_omits_full_ui_collections() {
        let (wake_tx, _wake_rx) = mpsc::sync_channel(1);
        let runtime = BridgeRuntime {
            application: Mutex::new(ApplicationHandle::spawn_without_update(|| {})),
            state: Mutex::new(BridgeState::default()),
            history: Mutex::new(RoomHistoryStore::load()),
            sinks: Mutex::new(Vec::new()),
            wake_tx,
            revision: AtomicU64::new(0),
        };
        let snapshot = ApplicationSnapshot::default();
        let state = BridgeState {
            snapshot_profile: SnapshotProfileDto::Lightweight,
            ..BridgeState::default()
        };

        let mapped = map_snapshot(&snapshot, &state, &runtime);
        assert_eq!(mapped.profile, SnapshotProfileDto::Lightweight);
        assert!(mapped.client_config.relays.is_empty());
        assert!(mapped.client_config.accounts.is_empty());
        assert!(mapped.room_history.is_empty());
        assert!(mapped.connection_tests.is_empty());
        assert!(mapped.logs.is_empty());
        assert!(mapped.lan_adapters.is_empty());
        runtime
            .application
            .lock()
            .expect("application lock")
            .request_shutdown();
    }

    #[test]
    fn application_initializes_only_once() {
        let first = initialize();
        assert!(first.accepted);
        let second = initialize();
        assert!(!second.accepted);
        assert_eq!(
            second.rejection.expect("duplicate rejection").code,
            "already_initialized"
        );
        assert!(shutdown().accepted);
    }

    #[test]
    fn select_relay_rejected_when_room_or_session_active() {
        let mut room_active_snapshot = ApplicationSnapshot::default();
        room_active_snapshot.relay_room_active = true;
        let err = validate_select_relay(&room_active_snapshot).expect_err("should reject");
        assert_eq!(
            err.rejection.as_ref().map(|r| r.code.as_str()),
            Some("room_or_session_active")
        );
        assert_eq!(
            err.rejection.as_ref().map(|r| r.display_text.as_str()),
            Some("请先退出房间再切换 Relay 节点")
        );

        let mut session_running_snapshot = ApplicationSnapshot::default();
        session_running_snapshot.runtime.status = SessionStatus::Running;
        let err2 = validate_select_relay(&session_running_snapshot).expect_err("should reject");
        assert_eq!(
            err2.rejection.as_ref().map(|r| r.code.as_str()),
            Some("room_or_session_active")
        );
        assert_eq!(
            err2.rejection.as_ref().map(|r| r.display_text.as_str()),
            Some("请先退出游戏再切换 Relay 节点")
        );

        let mut both_active_snapshot = ApplicationSnapshot::default();
        both_active_snapshot.relay_room_active = true;
        both_active_snapshot.runtime.status = SessionStatus::Running;
        let err3 = validate_select_relay(&both_active_snapshot).expect_err("should reject");
        assert_eq!(
            err3.rejection.as_ref().map(|r| r.display_text.as_str()),
            Some("请先退出游戏并离开房间再切换 Relay 节点")
        );

        let idle_snapshot = ApplicationSnapshot::default();
        assert!(validate_select_relay(&idle_snapshot).is_ok());
    }

    #[test]
    fn switching_steam_account_in_active_relay_room_does_not_duplicate_members() {
        let (wake_tx, _wake_rx) = mpsc::sync_channel(1);
        let runtime = BridgeRuntime {
            application: Mutex::new(ApplicationHandle::spawn_without_update(|| {})),
            state: Mutex::new(BridgeState::default()),
            history: Mutex::new(RoomHistoryStore::load()),
            sinks: Mutex::new(Vec::new()),
            wake_tx,
            revision: AtomicU64::new(0),
        };

        let mut snapshot = ApplicationSnapshot::default();
        snapshot.relay_room_active = true;
        snapshot.runtime.relay_room_steam_id64 = Some(76_561_198_000_000_001);
        snapshot.runtime.room_peers = vec![
            tractor_beam_core::protocol::PeerPresenceInfo {
                steam_id64: 76_561_198_000_000_001,
                display_name: Some("OldAccount".to_owned()),
                presence: tractor_beam_core::protocol::PeerPresence::Connected,
                capabilities: Default::default(),
            },
            tractor_beam_core::protocol::PeerPresenceInfo {
                steam_id64: 76_561_198_000_000_009,
                display_name: Some("Teammate".to_owned()),
                presence: tractor_beam_core::protocol::PeerPresence::Connected,
                capabilities: Default::default(),
            },
        ];

        let state = BridgeState {
            selected_steam_id64: Some("76561198000000002".to_owned()),
            manual_steam_accounts: vec![tractor_beam_core::ManualSteamAccount {
                steam_id64: "76561198000000002".to_owned(),
                display_name: "NewManualAccount".to_owned(),
            }],
            ..BridgeState::default()
        };

        let mapped = map_snapshot(&snapshot, &state, &runtime);
        // Room members must be exactly 2 (Local new account + Teammate), never 3!
        assert_eq!(mapped.room.members.len(), 2);
        assert_eq!(mapped.room.members[0].steam_id64, "76561198000000002");
        assert!(mapped.room.members[0].is_local);
        assert_eq!(mapped.room.members[0].display_name, "NewManualAccount");
        assert_eq!(mapped.room.members[1].steam_id64, "76561198000000009");
        assert!(!mapped.room.members[1].is_local);

        runtime
            .application
            .lock()
            .expect("application lock")
            .request_shutdown();
    }

    #[test]
    fn manually_saving_identical_steam_account_in_active_relay_room_does_not_duplicate_members() {
        let (wake_tx, _wake_rx) = mpsc::sync_channel(1);
        let runtime = BridgeRuntime {
            application: Mutex::new(ApplicationHandle::spawn_without_update(|| {})),
            state: Mutex::new(BridgeState::default()),
            history: Mutex::new(RoomHistoryStore::load()),
            sinks: Mutex::new(Vec::new()),
            wake_tx,
            revision: AtomicU64::new(0),
        };

        let mut snapshot = ApplicationSnapshot::default();
        snapshot.relay_room_active = true;
        snapshot.runtime.relay_room_steam_id64 = Some(76_561_198_000_000_001);
        snapshot.runtime.room_peers = vec![tractor_beam_core::protocol::PeerPresenceInfo {
            steam_id64: 76_561_198_000_000_001,
            display_name: Some("SameAccount".to_owned()),
            presence: tractor_beam_core::protocol::PeerPresence::Connected,
            capabilities: Default::default(),
        }];

        // Manually saving the EXACT SAME steam account ID
        let state = BridgeState {
            selected_steam_id64: Some("76561198000000001".to_owned()),
            manual_steam_accounts: vec![tractor_beam_core::ManualSteamAccount {
                steam_id64: "76561198000000001".to_owned(),
                display_name: "SameAccount".to_owned(),
            }],
            ..BridgeState::default()
        };

        let mapped = map_snapshot(&snapshot, &state, &runtime);
        // Room members must be strictly 1, never 2!
        assert_eq!(mapped.room.members.len(), 1);
        assert_eq!(mapped.room.members[0].steam_id64, "76561198000000001");
        assert!(mapped.room.members[0].is_local);
        assert_eq!(mapped.room.members[0].display_name, "SameAccount");

        runtime
            .application
            .lock()
            .expect("application lock")
            .request_shutdown();
    }
}
