package Queex::SPI;
use strict;
use Encode;
use JSON::XS;
use Data::Dumper;
use Time::HiRes;
use Hash::Merge;
use Clone;
use WWW::Easy::Auth;
use List::Util;
use locale;
require "utf8_heavy.pl";

sub uniq_array { 
	my %x;
	return ( grep { my $ok = !$x{$_}; $x{$_} = 1; $ok } @_ ) ;	
}

sub from_json { 
	return JSON::XS::decode_json(Encode::encode_utf8($_[0]));
}
sub to_json {
	return Encode::decode_utf8( JSON::XS::encode_json($_[0]));
}
sub unbless_arrays_in_rows { 
	my $rows = shift;
	foreach my $r (@$rows) {
		foreach my $k ( keys %$r) { 
			if (UNIVERSAL::isa($r->{$k} , 'PostgreSQL::InServer::ARRAY')) { 
				$r->{$k} = $r->{$k}->{array};
			}
			
		}
	}
}
sub parse_bool { 
	my $v = shift;
	return defined($v) ? ($v eq 't' || $v eq 'true' ? 1 : 0 ) : undef;
}

sub parse_daterange { 
	my $range = shift;
	$range =~ s/^\(|\)$//gs;
	return [ map { $_ || undef } split(/,/, $range) ];
}

sub parse_timerange { 
	my $range = shift;
	$range =~ /^(\[|\()(?:"([^"]+)")?,(?:"([^"]+)")?(\]|\))/; 
	return [$1,$2,$3,$4];
}

sub spi_run_query {  # toDo: cache
	my ($sql, $types, $values) = @_;
	my $h   = ::spi_prepare($sql, @$types);
	my $ret = ::spi_exec_prepared($h, @$values);
	## todo: check and log errors
	if($ret) { 
		unbless_arrays_in_rows( $ret->{rows} );
	}
	::spi_freeplan($h);
	return $ret;
}

sub spi_run_query_json_list { 
	my ($sql, $types, $values) = @_;
	return Queex::SPI::from_json( 
			Queex::SPI::spi_run_query(
				q!select coalesce(json_agg(row_to_json(x)),'[]'::json) AS x FROM (!.
				$sql.
				q! ) x!, $types, $values )->{rows}->[0]->{x}
	);
}
sub spi_run_query_bool { 
	my ($sql, $types, $values) = @_;
	return Queex::SPI::parse_bool(
			Queex::SPI::spi_run_query($sql .' AS x', $types, $values)->{rows}->[0]->{x}
	);
}
sub spi_run_query_row { 
	my ($sql, $types, $values) = @_;
	return Queex::SPI::spi_run_query($sql, $types, $values )->{rows}->[0];
}

1;
