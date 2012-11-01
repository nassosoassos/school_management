#!/usr/bin/perl
use strict;
use warnings;

my $semesters_csv_file = shift @ARGV;
my $lessons_csv_file = shift @ARGV;
my $semester_lessons_csv_file = shift @ARGV;
my $students_csv_file = shift @ARGV;
my $database_name = 'sandb';

open(SEM, "$semesters_csv_file") or die("Cannot open file $semesters_csv_file\n");
my %semesters;
my %academic_years;
my %groups;
my $year_id = 1;
my $group_id = 1;
my $line_no = 1;
my $semester_id = 1;
while (<SEM>) {
    if ($line_no==1) {
        $line_no = 2;
    }
    else {
        my $line = $_;
        chomp($line);
        $line =~ s/\'//g;
        my @line_info = split(',', $line);
        my $description = $line_info[3];
        my @year_info = split(' ', $description);
        my $start_year = $year_info[1];
        my $end_year = $year_info[3];
        if (not exists $academic_years{$start_year}) {
            my $finish_year = $start_year+1;
            my %year_hash = (
                'start_date' => "to_date(\'09/$start_year\',\'MM/RRRR\')",
                'end_date' => "to_date(\'08/$finish_year\',\'MM/RRRR\')",
                'id' => $year_id,
            );
            $academic_years{$start_year} = \%year_hash;
            $year_id++;
        }
        if (not exists $groups{$start_year}) {
            my %group_hash = (
                'name' => "Τάξη $start_year-$end_year",
                'id' => $group_id,
                'first_year' => $start_year,
                'graduation_year' => $end_year,
            );
            $groups{$start_year} = \%group_hash;
            $group_id++;
        }

        my %semester = (
            'old_id' => $line_info[0],
            'number' => $line_info[2],
            'uni_weight'=> $line_info[5],
            'mil_weight'=> $line_info[6],
            'academic_year_id'=> $academic_years{$start_year}->{'id'},
            'group_id' => $groups{$start_year}->{'id'},
            'id' => $semester_id,
        );
        $semesters{$line_info[0]} =  \%semester;
        $semester_id++;
    }
}
close(SEM);

open(LESSONS, "$lessons_csv_file") or die("Cannot open file $lessons_csv_file\n");

my %lessons;
my $lesson_id = 1;
$line_no = 1;
while (<LESSONS>) {
    if ($line_no==1) {
        $line_no = 2;
    }
    else {
        my $line = $_;
        chomp($line);
        $line =~ s/\'//g;
        my @line_info = split(',', $line);
        my $kind = 'University';
        if ($line_info[2] =~ /Military/) {
            $kind = 'Military';
        }
        my $old_id = $line_info[0];
        my %lesson_hash = (
                'old_id' => $old_id,
                'title' => $line_info[1],
                'kind' => $kind,
                'id' => $lesson_id,
        );
        $lessons{$old_id} = \%lesson_hash;
        $lesson_id++;
    }
}

close(LESSONS);

open(SEM_LESSONS, "$semester_lessons_csv_file") or die("Cannot open file $semester_lessons_csv_file\n");
my %semester_lessons;
my $semester_lesson_id = 1;
$line_no = 1;
while (<SEM_LESSONS>) {
    if ($line_no==1) {
        $line_no = 2;
    }
    else {
        my $line = $_;
        chomp($line);
        $line =~ s/\'//g;
        my @line_info = split(',', $line);
        my $is_optional = 'FALSE';
        if ($line_info[4] =~ 'O') {
            $is_optional = 'TRUE';
        }
        my $old_id = $line_info[0];
        my %sem_lesson_hash = (
                'old_id' => $old_id,
                'semester_id' => $semesters{$line_info[1]}->{'id'},
                'subject_id' => $lessons{$line_info[2]}->{'id'},
                'optional' => $is_optional,
                'id' => $lesson_id,
        );
        $semester_lessons{$old_id} = \%sem_lesson_hash;
        $semester_lesson_id++;
    }
}

close(SEM_LESSONS);

insert_data_into_table("san_subjects", \%lessons, "insert_san_subjects.sql");
insert_data_into_table("academic_years", \%academic_years, "insert_academic_years.sql");
insert_data_into_table("groups", \%groups, "insert_groups.sql");
insert_data_into_table("san_semesters", \%semesters, "insert_san_semesters.sql");
insert_data_into_table("semester_subjects", \%semester_lessons, "insert_semester_subjects.sql");
        
sub insert_data_into_table {
    my ($table_name, $data_ref, $file_name) = @_;

    open(SQL, ">$file_name") or die("Cannot open $file_name for writing.\n");

    foreach my $entry_id (keys %$data_ref) {
        my $entry = $data_ref->{$entry_id};
        print SQL "Insert into `$database_name`.`$table_name` (";
        my @entry_keys = keys(%$entry);
        my $n_fields = @entry_keys;
        my $ind = 1;
        foreach my $field (@entry_keys) {
            print SQL "`$field`";
            if ($ind<$n_fields) {
                print SQL ",";
            }
            $ind++;
        }
        print SQL ") values (";
        $ind = 1;
        foreach my $field (@entry_keys) {
            my $val = $entry->{$field};
            if (($val =~ /to_date/) or ($val =~ "TRUE") or ($val =~ "FALSE")) {
                print SQL "$val";
            }
            else {
                print SQL "\'$val\'";
            }
            if ($ind<$n_fields) {
                print SQL ",";
            }
            $ind++;
        }
        print SQL ");\n";
    }
    close(SQL);
}
