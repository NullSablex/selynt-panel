<?php
define('SELYNT_VERSION',    '0.1.0');
define('SELYNT_BIN',        dirname(__DIR__) . '/bin/core_selynt');
define('SELYNT_PLUGIN_DIR', dirname(__DIR__));

function selynt_debug_mode(): bool {
    return getenv('SELYNT_DEBUG') !== false
        || file_exists(SELYNT_PLUGIN_DIR . '/etc/debug');
}

/**
 * Resolve o home real do usuário atual.
 * Cadeia: posix_getpwnam(USERNAME) → /home/$USERNAME → posix_geteuid → HOME env.
 * Idêntico ao home_dir() do selyntctl antigo para garantir robustez no contexto CGI do DA.
 */
function selynt_home(): string {
    $u = trim((string)getenv('USERNAME'));
    if ($u !== '') {
        if (function_exists('posix_getpwnam')) {
            $pw = @posix_getpwnam($u);
            if (is_array($pw) && isset($pw['dir']) && (string)$pw['dir'] !== '') {
                return rtrim($pw['dir'], '/');
            }
        }
        return '/home/' . $u;
    }
    // USERNAME vazio: resolver pelo eUID real do processo
    if (function_exists('posix_getpwuid') && function_exists('posix_geteuid')) {
        $pw = @posix_getpwuid(@posix_geteuid());
        if (is_array($pw) && isset($pw['dir']) && (string)$pw['dir'] !== '') {
            return rtrim($pw['dir'], '/');
        }
    }
    return rtrim((string)getenv('HOME'), '/');
}

function selynt_run(array $args): array {
    if (!is_executable(SELYNT_BIN)) {
        return ['ok' => false, 'error' => 'binary_missing', 'message' => 'Binário core_selynt não encontrado.'];
    }

    $home = selynt_home();
    if ($home === '') {
        return ['ok' => false, 'error' => 'home_not_found', 'message' => 'Não foi possível determinar o home do usuário.'];
    }

    $debug     = selynt_debug_mode();
    $username  = selynt_username();
    $state_dir = '/var/lib/selynt_panel/' . $username;

    // Passa HOME, USERNAME e SELYNT_STATE_DIR explicitamente para o binário.
    // HOME: para o binário resolver cwd dos apps no home do user.
    // USERNAME: para o binário resolver uid/gid do user real (drop de privilégio).
    $cmd  = 'HOME=' . escapeshellarg($home);
    $cmd .= ' USERNAME=' . escapeshellarg($username);
    $cmd .= ' SELYNT_STATE_DIR=' . escapeshellarg($state_dir);
    $cmd .= ' ' . SELYNT_BIN;
    foreach ($args as $arg) {
        $cmd .= ' ' . escapeshellarg((string)$arg);
    }

    // proc_open: captura stdout e stderr sem depender de nenhum arquivo externo.
    $desc = [
        0 => ['pipe', 'r'],
        1 => ['pipe', 'w'],
        2 => ['pipe', 'w'],
    ];
    $proc = @proc_open($cmd, $desc, $pipes);
    if (!is_resource($proc)) {
        return ['ok' => false, 'error' => 'exec_failed', 'message' => 'Falha ao executar o binário.'];
    }
    fclose($pipes[0]);
    $stdout = stream_get_contents($pipes[1]); fclose($pipes[1]);
    $stderr = stream_get_contents($pipes[2]); fclose($pipes[2]);
    $exit_code = proc_close($proc);

    $result = json_decode($stdout, true);
    if (!is_array($result)) {
        // Sempre mostra o que veio do binário — sem depender de debug mode
        return [
            'ok'      => false,
            'error'   => 'binary_error',
            'message' => $stdout !== '' ? $stdout : ($stderr !== '' ? $stderr : 'Sem saída (exit=' . $exit_code . ')'),
            'exit'    => $exit_code,
        ];
    }
    return $result;
}

function selynt_json(array $data, int $code = 200): void {
    $texts = [200 => 'OK', 201 => 'Created', 400 => 'Bad Request', 405 => 'Method Not Allowed'];
    $text  = $texts[$code] ?? 'Error';
    echo "HTTP/1.1 $code $text\n";
    echo "Cache-Control: no-cache, must-revalidate\n";
    echo "X-Content-Type-Options: nosniff\n";
    echo "X-Frame-Options: SAMEORIGIN\n";
    echo "Content-Type: application/json\n\n";
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}

function selynt_method(): string {
    return strtoupper(trim((string)getenv('REQUEST_METHOD'))) ?: 'GET';
}

function selynt_input(): array {
    $data = [];
    parse_str((string)getenv('QUERY_STRING'), $data);

    if (selynt_method() !== 'POST') return $data;

    // Content-Length: DA CGI pode usar CONTENT_LENGTH ou HTTP_CONTENT_LENGTH
    $len = (int)getenv('CONTENT_LENGTH');
    if ($len <= 0) $len = (int)getenv('HTTP_CONTENT_LENGTH');

    // Ler body: fread(STDIN) com length, ou php://input como fallback
    $body = '';
    if ($len > 0) {
        $body = (string)fread(STDIN, min($len, 4 * 1024 * 1024));
    }
    if ($body === '') {
        $body = (string)@file_get_contents('php://input');
    }
    if ($body === '') return $data;

    // Content-Type: DA CGI pode usar CONTENT_TYPE ou HTTP_CONTENT_TYPE
    $ct = (string)getenv('CONTENT_TYPE');
    if ($ct === '') $ct = (string)getenv('HTTP_CONTENT_TYPE');

    // JSON: por content-type ou detecção de { no início
    if (strpos($ct, 'application/json') !== false || ($body[0] ?? '') === '{') {
        $decoded = json_decode($body, true);
        if (is_array($decoded)) return $decoded;
    }

    // Fallback: form-encoded
    $post = [];
    parse_str($body, $post);
    return array_merge($data, $post);
}

/**
 * Exige método POST. Retorna JSON 405 e encerra se não for POST.
 * Autenticação e sessão são gerenciadas pelo DirectAdmin.
 */
function selynt_require_post(): void {
    if (selynt_method() !== 'POST') {
        selynt_json(['ok' => false, 'error' => 'method_not_allowed', 'message' => 'POST obrigatório.'], 405);
        exit(0);
    }
}

function selynt_username(): string {
    $u = trim((string)getenv('USERNAME'));
    if ($u !== '') return $u;
    if (function_exists('posix_getpwuid') && function_exists('posix_geteuid')) {
        $pw = @posix_getpwuid(@posix_geteuid());
        if (is_array($pw) && isset($pw['name']) && (string)$pw['name'] !== '') {
            return $pw['name'];
        }
    }
    return '';
}
