/**
 * Selynt Panel — Node.js loader
 * Injected via --import before the user's app.
 * Intercepts net.Server.listen() to force binding on the Unix socket.
 * Blocks dgram (UDP) to prevent opening ports.
 *
 * Error messages honour SELYNT_LOCALE when set by the spawn helper.
 */

import net from 'node:net';
import dgram from 'node:dgram';

const MESSAGES = {
  'en': {
    no_socket: '[selynt] SELYNT_SOCKET is not defined.',
    tcp_port_forbidden: '[selynt] Binding to a TCP port is not allowed.',
    tcp_host_forbidden: '[selynt] Binding to a TCP port/host is not allowed.',
    udp_bind_forbidden: '[selynt] UDP bind is not allowed.',
    udp_create_forbidden: '[selynt] UDP sockets are not allowed.',
  },
  'pt-br': {
    no_socket: '[selynt] SELYNT_SOCKET não definido.',
    tcp_port_forbidden: '[selynt] Bind em porta TCP não é permitido.',
    tcp_host_forbidden: '[selynt] Bind em porta/host TCP não é permitido.',
    udp_bind_forbidden: '[selynt] Bind UDP não é permitido.',
    udp_create_forbidden: '[selynt] Sockets UDP não são permitidos.',
  },
};

function pickLocale() {
  const raw = String(process.env.SELYNT_LOCALE || '').toLowerCase().replace('_', '-');
  if (MESSAGES[raw]) return raw;
  const prefix = raw.split('-')[0];
  if (MESSAGES[prefix]) return prefix;
  return 'en';
}

const M = MESSAGES[pickLocale()];

const _listen = net.Server.prototype.listen;
const SOCKET = process.env.SELYNT_SOCKET;

if (!SOCKET) {
  throw new Error(M.no_socket);
}

// TCP: redirect listen to the Unix socket
net.Server.prototype.listen = function (...args) {
  const first = args[0];

  if (typeof first === 'number' || (typeof first === 'string' && /^\d+$/.test(first))) {
    throw new Error(M.tcp_port_forbidden);
  }
  if (typeof first === 'object' && first !== null && (first.port !== undefined || first.host !== undefined)) {
    throw new Error(M.tcp_host_forbidden);
  }

  const cb = typeof args[args.length - 1] === 'function' ? args[args.length - 1] : undefined;
  return _listen.call(this, SOCKET, cb);
};

// UDP: block bind and createSocket
dgram.Socket.prototype.bind = function () {
  throw new Error(M.udp_bind_forbidden);
};

dgram.createSocket = function () {
  throw new Error(M.udp_create_forbidden);
};
