// Copyright 2016 The Fuchsia Authors
//
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT

#include <magenta/state_tracker.h>

#include <kernel/auto_lock.h>
#include <magenta/wait_event.h>

void StateTracker::AddObserver(StateObserver* observer) {
    DEBUG_ASSERT(observer != nullptr);

    bool awoke_threads = false;
    {
        AutoLock lock(&lock_);

        awoke_threads = observer->OnInitialize(signals_);
        if (!observer->remove())
            observers_.push_front(observer);
    }
    if (awoke_threads)
        thread_preempt(false);
}

void StateTracker::RemoveObserver(StateObserver* observer) {
    AutoLock lock(&lock_);
    DEBUG_ASSERT(observer != nullptr);
    observers_.erase(*observer);
}

void StateTracker::Cancel(Handle* handle) {
    bool awoke_threads = false;

    ObserverList obs_to_remove;

    {
        AutoLock lock(&lock_);
        for (auto it = observers_.begin(); it != observers_.end();) {
            awoke_threads = it->OnCancel(handle) || awoke_threads;
            if (it->remove()) {
                auto to_remove = it;
                ++it;
                obs_to_remove.push_back(observers_.erase(to_remove));
            } else {
                ++it;
            }
        }
    }

    RemoveObservers(&obs_to_remove);

    if (awoke_threads)
        thread_preempt(false);
}

void StateTracker::UpdateState(mx_signals_t clear_mask,
                               mx_signals_t set_mask) {
    bool awoke_threads = false;

    ObserverList obs_to_remove;

    {
        AutoLock lock(&lock_);

        auto previous_signals = signals_;
        signals_ &= ~clear_mask;
        signals_ |= set_mask;

        if (previous_signals == signals_)
            return;

        for (auto it = observers_.begin(); it != observers_.end();) {
            awoke_threads = it->OnStateChange(signals_) || awoke_threads;
            if (it->remove()) {
                auto to_remove = it;
                ++it;
                obs_to_remove.push_back(observers_.erase(to_remove));
            } else {
                ++it;
            }
        }
    }

    RemoveObservers(&obs_to_remove);

    if (awoke_threads) {
        thread_preempt(false);
    }
}

void StateTracker::RemoveObservers(ObserverList* list) {
    while (!list->is_empty()) {
        list->pop_front()->OnRemoved();
    }
}
