module main

import os

fn req(name string) DownloadCountRequest {
	return DownloadCountRequest{
		name:       name
		server_url: 'https://nowhere.invalid'
	}
}

// always_succeed is what a disabled download-count increment reduces to.
fn always_succeed(_req DownloadCountRequest) bool {
	return true
}

// fails_only_for reports success for every request except the named ones, so the
// pooling can be checked without reaching a registry.
fn fails_only_for(names []string) fn (DownloadCountRequest) bool {
	return fn [names] (req DownloadCountRequest) bool {
		return req.name !in names
	}
}

fn test_no_requests_reports_nothing() {
	assert report_all([], always_succeed).len == 0
}

fn test_a_single_request_takes_the_serial_path() {
	assert report_all([req('solo')], always_succeed).len == 0
}

fn test_every_successful_request_is_counted_once() {
	names := ['a', 'b', 'c', 'd', 'e', 'f', 'g']
	assert report_all(names.map(req), always_succeed).len == 0
}

// More requests than workers still drains the whole queue. A worker that stops
// early would leave a result uncollected, and this test would hang rather than
// fail, which is the signal to look for.
fn test_more_requests_than_workers_still_completes() {
	mut names := []string{}
	for i in 0 .. (download_count_concurrency * 3) {
		names << 'm${i}'
	}
	assert report_all(names.map(req), always_succeed).len == 0
}

fn test_a_failing_request_is_reported_once_by_name() {
	failed := report_all([req('a'), req('b'), req('c')], fails_only_for(['b']))
	assert failed == ['b'], 'expected only `b` to fail, got ${failed}'
}

// Several failures must all come back, and each only once: a result collected
// twice or dropped once would show up here.
fn test_every_failure_comes_back_exactly_once() {
	mut names := []string{}
	for i in 0 .. (download_count_concurrency * 2) {
		names << 'n${i}'
	}
	failed := report_all(names.map(req), fails_only_for(names))
	assert failed.len == names.len, 'expected ${names.len} failures, got ${failed.len}'
	for name in names {
		assert name in failed, '`${name}` was not reported as failed'
	}
}

// The names come back in request order, so a caller reading them gets the same
// order the modules were listed in.
fn test_failures_come_back_in_request_order() {
	names := ['first', 'second', 'third', 'fourth']
	failed := report_all(names.map(req), fails_only_for(['third', 'first']))
	assert failed == ['first', 'third'], 'expected request order, got ${failed}'
}
