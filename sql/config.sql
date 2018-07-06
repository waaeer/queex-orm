

CREATE TYPE config_node_type  AS ENUM ('group','text');
CREATE TABLE config (
	id      INT primary key DEFAULT nextval('id_seq'),
	name	TEXT NOT NULL,
	parent  INT  REFERENCES config(id),
	type	config_node_type NOT NULL DEFAULT 'text',
	value	TEXT
);	

CREATE INDEX config_parent ON config(parent);
INSERT INTO  config (id,name,type)         VALUES (1,'system','group');
INSERT INTO  config (id,name,parent,value) VALUES (2,'file_storage_root', 1, '/.crm/media');



CREATE OR REPLACE FUNCTION get_config(path TEXT) RETURNS text SECURITY DEFINER LANGUAGE plperl AS $$
	my $path = shift;
	my $rec;
	my $sth = spi_prepare('select * from config where parent is not distinct from $1 and name = $2 order by id limit 1', 'int', 'text');
	foreach my $element (grep { $_ } split("/", $path)) { 
		$rec = spi_exec_prepared($sth,  $rec ? $rec->{id} : undef, $element)->{rows}->[0];
		warn $rec;
		if(!$rec) { return undef; } 
	} 
	return $rec ? $rec->{value} : undef;
$$;

GRANT EXECUTE ON FUNCTION get_config(text) TO httpd;

