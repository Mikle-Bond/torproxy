# MAINTAINER Mikle Bond <mikle_bond@mail.ru>
# MAINTAINER David Personette <dperson@gmail.com>

FROM golang:alpine AS go-build

# Build /go/bin/obfs4proxy & /go/bin/meek-server
RUN <<-"EOF"
	set -euo pipefail
	apk --no-cache add --update git
	go install -v gitlab.com/yawning/obfs4.git/obfs4proxy@latest
	go install -v git.torproject.org/pluggable-transports/meek.git/meek-server@latest
	cp -rv /go/bin /usr/local/
EOF

FROM alpine

COPY --from=go-build /usr/local/bin/ /usr/local/bin/

# Install tor and privoxy
RUN <<-"EOF"
	apk --no-cache --no-progress upgrade
	apk --no-cache --no-progress add `
	` bash `
	` curl `
	` privoxy `
	` shadow `
	` tini `
	` tor `
	` tzdata `
	`

	cat `
	` >/etc/privoxy/config `
	` <(grep -vE '(^#|accept-intercepted-requests|listen.*1|logfile|actionsfile|filterfile)' /etc/privoxy/config.new) `
	` - <<-"config"
		confdir /etc/privoxy
		listen-address 0.0.0.0:8118
		accept-intercepted-requests 1
		log-messages
		log-highlight-messages
		forward-socks5t / 127.0.0.1:9050 .
		forward 172.16.*.*/ .
		forward 172.17.*.*/ .
		forward 172.18.*.*/ .
		forward 172.19.*.*/ .
		forward 172.20.*.*/ .
		forward 172.21.*.*/ .
		forward 172.22.*.*/ .
		forward 172.23.*.*/ .
		forward 172.24.*.*/ .
		forward 172.25.*.*/ .
		forward 172.26.*.*/ .
		forward 172.27.*.*/ .
		forward 172.28.*.*/ .
		forward 172.29.*.*/ .
		forward 172.30.*.*/ .
		forward 172.31.*.*/ .
		forward 10.*.*.*/ .
		forward 192.168.*.*/ .
		forward 127.*.*.*/ .
		forward localhost/ .
	config
	rm /etc/privoxy/*.new

	mkdir -p /etc/tor/run
	chown -Rh tor /var/lib/tor /etc/tor/run
	chmod 0750 /etc/tor/run
	rm -rf /tmp/*
EOF

COPY --chmod=0750 torrc /etc/tor/

COPY torproxy.sh /usr/bin/

EXPOSE 8118 9050 9051

HEALTHCHECK --interval=60s --timeout=15s --start-period=20s \
			CMD curl -sx localhost:8118 'https://check.torproject.org/' | \
			grep -qm1 Congratulations

VOLUME ["/var/lib/tor"]

ENTRYPOINT ["/sbin/tini", "--", "/usr/bin/torproxy.sh"]
