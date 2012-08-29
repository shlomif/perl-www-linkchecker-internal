use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::LinkChecker::Internal',
    license             => 'mit',
    dist_author         => q{Shlomi Fish <shlomif@cpan.org>},
    dist_version_from   => 'lib/WWW/LinkChecker/Internal.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Getopt::Long' => 0,
        'WWW::Mechanize' => 0,
        'perl' => 5.006,
        'strict' => 0,
        'warnings' => 0,
    },
    add_to_cleanup      => [ 'WWW-LinkChecker-Internal-*' ],
    create_makefile_pl => 'traditional',
    script_files =>
    [
        'scripts/link-checker',
    ],
);

$builder->create_build_script();
