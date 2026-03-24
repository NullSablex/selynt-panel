/**
 * Selynt Panel — Node.js loader
 * Injetado via --import antes do app do usuário.
 * Intercepta net.Server.listen() para forçar bind no Unix socket.
 * Bloqueia dgram (UDP) para impedir abertura de portas.
 */

import net from 'node:net';
import dgram from 'node:dgram';

const _listen = net.Server.prototype.listen;
const SOCKET = process.env.SELYNT_SOCKET;

if (!SOCKET) {
  throw new Error('[selynt] SELYNT_SOCKET não definido.');
}

// TCP: redireciona listen para o Unix socket
net.Server.prototype.listen = function (...args) {
  const first = args[0];

  if (typeof first === 'number' || (typeof first === 'string' && /^\d+$/.test(first))) {
    throw new Error('[selynt] Bind em porta TCP não é permitido.');
  }
  if (typeof first === 'object' && first !== null && (first.port !== undefined || first.host !== undefined)) {
    throw new Error('[selynt] Bind em porta/host TCP não é permitido.');
  }

  const cb = typeof args[args.length - 1] === 'function' ? args[args.length - 1] : undefined;
  return _listen.call(this, SOCKET, cb);
};

// UDP: bloquear bind e createSocket
dgram.Socket.prototype.bind = function () {
  throw new Error('[selynt] Bind UDP não é permitido.');
};

dgram.createSocket = function () {
  throw new Error('[selynt] Sockets UDP não são permitidos.');
};
