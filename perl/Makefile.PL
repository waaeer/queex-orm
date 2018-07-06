use strict;
use warnings;

use Module::Build;

my $root = "lib";
my $builder = Module::Build->new(
        module_name     => 'Queex::SPI',
        license         => 'perl',
        dist_version    => '4.0.0',
        dist_author     => 'Ivan Panchenko <ivan.e.panchenko@gmail.com>',
        dist_abstract   => '',
        requires        => {
        },
        pm_files        => {
                'lib/Queex/SPI.pm'     => "$root/Queex/SPI.pm",
        },
);

$builder->create_build_script();