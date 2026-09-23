use std::collections::{HashMap, VecDeque};
use std::time::{Duration, Instant};

pub(super) const ROOM_RTT_NAMESPACE: u64 = 1 << 63;
const ROLLING_SAMPLE_COUNT: usize = 5;
const STALE_THRESHOLD: Duration = Duration::from_secs(4);
const PENDING_TIMEOUT: Duration = Duration::from_secs(5);

#[derive(Debug)]
pub(super) struct RelayRttTracker {
    next_counter: u64,
    pending: HashMap<u64, Instant>,
    recent_rtts: VecDeque<Duration>,
    last_update: Option<Instant>,
}

impl Default for RelayRttTracker {
    fn default() -> Self {
        Self {
            next_counter: 1,
            pending: HashMap::new(),
            recent_rtts: VecDeque::with_capacity(ROLLING_SAMPLE_COUNT),
            last_update: None,
        }
    }
}

impl RelayRttTracker {
    pub(super) fn next_ping(&mut self, now: Instant) -> u64 {
        let counter = self.next_counter;
        self.next_counter = self.next_counter.wrapping_add(1);
        let id = ROOM_RTT_NAMESPACE | counter;
        self.pending.insert(id, now);
        id
    }

    pub(super) fn observe_pong(&mut self, id: u64, now: Instant) -> Option<Duration> {
        let sent_at = self.pending.remove(&id)?;
        let rtt = now.duration_since(sent_at);
        if self.recent_rtts.len() >= ROLLING_SAMPLE_COUNT {
            self.recent_rtts.pop_front();
        }
        self.recent_rtts.push_back(rtt);
        self.last_update = Some(now);
        self.current_rtt(now)
    }

    pub(super) fn expire(&mut self, now: Instant) {
        self.pending
            .retain(|_, sent_at| now.duration_since(*sent_at) <= PENDING_TIMEOUT);
    }

    pub(super) fn is_stale(&self, now: Instant) -> bool {
        self.last_update
            .is_none_or(|last| now.duration_since(last) > STALE_THRESHOLD)
    }

    pub(super) fn current_rtt(&self, now: Instant) -> Option<Duration> {
        if self.is_stale(now) || self.recent_rtts.is_empty() {
            return None;
        }
        let mut sorted: Vec<Duration> = self.recent_rtts.iter().copied().collect();
        sorted.sort();
        let mid = sorted.len() / 2;
        Some(sorted[mid])
    }

    pub(super) fn reset(&mut self) {
        self.pending.clear();
        self.recent_rtts.clear();
        self.last_update = None;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn ping_ids_use_namespace() {
        let mut tracker = RelayRttTracker::default();
        let now = Instant::now();
        let id1 = tracker.next_ping(now);
        let id2 = tracker.next_ping(now);
        assert_ne!(id1, id2);
        assert_ne!(id1 & ROOM_RTT_NAMESPACE, 0);
        assert_ne!(id2 & ROOM_RTT_NAMESPACE, 0);
    }

    #[test]
    fn single_ping_pong_calculates_rtt() {
        let mut tracker = RelayRttTracker::default();
        let start = Instant::now();
        let id = tracker.next_ping(start);

        let pong_time = start + Duration::from_millis(30);
        let rtt = tracker.observe_pong(id, pong_time);
        assert_eq!(rtt, Some(Duration::from_millis(30)));
        assert_eq!(
            tracker.current_rtt(pong_time),
            Some(Duration::from_millis(30))
        );
    }

    #[test]
    fn rolling_median_samples() {
        let mut tracker = RelayRttTracker::default();
        let base = Instant::now();

        // Feed 5 samples: 50ms, 20ms, 40ms, 10ms, 30ms -> sorted: [10, 20, 30, 40, 50], median: 30ms
        let delays = [50, 20, 40, 10, 30];
        let mut current_time = base;
        for &ms in &delays {
            let id = tracker.next_ping(current_time);
            current_time += Duration::from_millis(ms);
            tracker.observe_pong(id, current_time);
        }

        assert_eq!(
            tracker.current_rtt(current_time),
            Some(Duration::from_millis(30))
        );
    }

    #[test]
    fn stale_threshold_clears_rtt() {
        let mut tracker = RelayRttTracker::default();
        let start = Instant::now();
        let id = tracker.next_ping(start);
        tracker.observe_pong(id, start + Duration::from_millis(25));

        assert!(
            tracker
                .current_rtt(start + Duration::from_millis(25))
                .is_some()
        );
        // After STALE_THRESHOLD + 1s, it becomes stale
        let later = start + Duration::from_secs(6);
        assert!(tracker.is_stale(later));
        assert_eq!(tracker.current_rtt(later), None);
    }

    #[test]
    fn reset_clears_all_state() {
        let mut tracker = RelayRttTracker::default();
        let start = Instant::now();
        let id = tracker.next_ping(start);
        tracker.observe_pong(id, start + Duration::from_millis(25));
        assert!(
            tracker
                .current_rtt(start + Duration::from_millis(25))
                .is_some()
        );

        tracker.reset();
        assert_eq!(tracker.current_rtt(start + Duration::from_millis(25)), None);
        assert!(tracker.is_stale(start + Duration::from_millis(25)));
    }
}
