<?php

declare(strict_types=1);

namespace Tests;

use PHPUnit\Framework\TestCase;

class PhpExtensionsTest extends TestCase
{
    /**
     * @var array|string[]
     */
    private array $phpIniConfig;

    protected function setUp(): void
    {
        $this->phpIniConfig = ini_get_all();
    }

    public function test_php_has_closed_list_of_extensions(): void
    {
        $expectedExtensions = [
            'Core',
            'date',
            'libxml',
            'openssl',
            'pcre',
            'sqlite3',
            'zlib',
            'ctype',
            'curl',
            'dom',
            'fileinfo',
            'filter',
            'ftp',
            'hash',
            'iconv',
            'json',
            'mbstring',
            'SPL',
            'PDO',
            'pdo_sqlite',
            'session',
            'posix',
            'readline',
            'Reflection',
            'standard',
            'SimpleXML',
            'Phar',
            'tokenizer',
            'xml',
            'xmlreader',
            'xmlwriter',
            'mysqlnd',
            'gd',
            'sodium',
            'mysqli',
            'pdo_mysql',
            'pdo_pgsql',
            'intl',
            'Zend OPcache',
            'apcu',
            'bcmath',
        ];

        if (true === isset($_SERVER['PHP_CLI_IS_XDEBUG_ENABLED']) && '1' === $_SERVER['PHP_CLI_IS_XDEBUG_ENABLED']) {
            $expectedExtensions = array_merge($expectedExtensions, ['xdebug']);
        }

        $actualExtensions = get_loaded_extensions();

        $missingExtensions = array_diff($expectedExtensions, $actualExtensions);
        $unnecessaryExtensions = array_diff($actualExtensions, $expectedExtensions);

        self::assertEmpty(
            $missingExtensions,
            sprintf("PHP does not have the following extensions: %s", implode(', ', $missingExtensions))
        );
        self::assertEmpty(
            $unnecessaryExtensions,
            sprintf("PHP has the following unnecessary extensions: %s", implode(', ', $unnecessaryExtensions))
        );
    }

    /**
     * @dataProvider correctConfigDataProvider
     *
     * @param string $expectedConfigName
     * @param string $expectedConfigValue
     */
    public function test_php_has_correct_config(string $expectedConfigName, string $expectedConfigValue): void
    {
        self::assertEquals($this->phpIniConfig[$expectedConfigName]['global_value'], $expectedConfigValue);
    }

    /**
     * @return array[]
     */
    public function correctConfigDataProvider(): array
    {
        return [
            ['sendmail_path', '/usr/bin/msmtp -t'],
            ['date.timezone', 'Europe/Moscow'],
            ['log_errors', '1'],
            ['error_log', '/dev/stderr'],
            ['error_reporting', (string) E_ALL],
            ['display_errors', '1'],
            ['mysqli.default_socket', '/usr/local/var/run/mysql.sock'],
            ['pdo_mysql.default_socket', '/usr/local/var/run/mysql.sock'],
        ];
    }
}
