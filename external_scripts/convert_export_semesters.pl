#!/usr/bin/perl
use strict;
use warnings;
use locale;
use POSIX;


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
        my $number = $line_info[2];
        my $description = $line_info[3];
        my @year_info = split(' ', $description);
        my $start_year = $year_info[1];
        my $end_year = $year_info[3];
        my $ac_year = $start_year + floor((($number+1)/2-1)); 
        if (not exists $academic_years{$ac_year}) {
            my $finish_year = $ac_year + 1;
            my %year_hash = (
                'start_date' => "STR_TO_DATE(\'01,09,$ac_year\',\'%d,%m,%Y\')",
                'end_date' => "STR_TO_DATE(\'31,08,$finish_year\',\'%d,%m, %Y\')",
                'id' => $year_id,
            );
            $academic_years{$ac_year} = \%year_hash;
            $year_id++;
        }
        if (not exists $groups{$start_year}) {
            my %group_hash = (
                'name' => "Τάξη $start_year-$end_year",
                'id' => $group_id,
                'first_year' => "STR_TO_DATE(\'01,09,$start_year\',\'%d,%m,%Y\')",
                'graduation_year' => "STR_TO_DATE(\'31,08,$end_year\',\'%d,%m,%Y\')",
            );
            $groups{$start_year} = \%group_hash;
            $group_id++;
        }
        my %semester = (
            'old_id' => $line_info[0],
            'number' => $line_info[2],
            'uni_weight'=> $line_info[5],
            'mil_weight'=> $line_info[6],
            'academic_year_id'=> $academic_years{$ac_year}->{'id'},
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
                'id' => $semester_lesson_id,
        );
        $semester_lessons{$old_id} = \%sem_lesson_hash;
        $semester_lesson_id++;
    }
}

close(SEM_LESSONS);

open(STUDENTS, "$students_csv_file") or die("Cannot open file $students_csv_file for reading");

my %students;
my %guardians;
my $student_id = 1;
my $guardian_id = 1;
$line_no = 1;
while (<STUDENTS>) {
    if ($line_no==1) {
        $line_no = 2;
    }
    else {
        my $line = $_;
        chomp($line);
        $line =~ s/\'//g;
        $line =~ s/to_date\(//g;
        $line =~ s/,DD\/MM\/RR\)//g;
        my @line_info = split(',', $line);
        my $old_id = $line_info[0];
        my $admission_date = "STR_TO_DATE(\'$line_info[8]\',\'%d/%m/%Y\')";
        my ($address_line, $group_id);
        my ($day, $month, $year) = split('\/', $line_info[8]);
        $group_id = $groups{'20'.$year}->{'id'};
        my $birth_date = "STR_TO_DATE(\'$line_info[11]\',\'%d/%m/%Y\')";
        if ($line_info[15] ne 'null') {
            $address_line = $line_info[14]." ".$line_info[15];
        }
        else {
            $address_line = 'null';
        }

        my $guardian_name = $line_info[5];
        my $gender = 'f';
        if ($line_info[1] =~ /Σ$/) {
            $gender = 'm';
        }

        my %student_hash = (
                'old_id' => $old_id,
                'last_name' => uc($line_info[1]),
                'first_name' => uc($line_info[2]),
                'fathers_first_name' => uc($line_info[3]),
                'mothers_first_name' => uc($line_info[4]),
                'admission_no' => $line_info[6],
                'uni_admission_no' => $line_info[7],
                'admission_date' => $admission_date,
                'birth_place' => uc($line_info[12]),
                'date_of_birth' => $birth_date,
                'address_line1' => uc($address_line),
                'city' => uc($line_info[13]),
                'pin_code' => $line_info[16],
                'group_id' => $group_id,
                'gender' => $gender,
                'nationality_id' => 66,
                'country_id' => 66,
                'id' => $student_id,
        );

        # Add guardian if necessary
        if ($guardian_name ne 'null') {
            my @guardian_info = split('\s', $guardian_name);
            my ($guardian_first_name, $guardian_last_name, $relation);
            if (@guardian_info>1) {
                $guardian_first_name = $guardian_info[0];
                $guardian_last_name = $guardian_info[1];
                if ($guardian_first_name eq $line_info[3]) {
                    $relation = 'father';
                }
                elsif ($guardian_last_name eq $line_info[4]) {
                    $relation = 'mother';
                }
                else {
                    $relation = 'unknown';
                }

            }
            else {
                $guardian_name =~ s/\s+//g;
                $guardian_first_name = $guardian_name;
                $guardian_last_name = $line_info[1];
                if ($guardian_first_name eq $line_info[3]) {
                    $relation = 'father';
                }
                else {
                    $relation = 'mother';
                }
            }
            my %guardian_hash = (
                'id' => $guardian_id,
                'ward_id' => $student_id,
                'first_name' => uc($guardian_first_name),
                'last_name' => uc($guardian_last_name),
                'relation' => $relation,
                'country_id' => 66,
            );
            $guardians{$student_id} = \%guardian_hash;
            $student_hash{"immediate_contact_id"} = $guardian_id;
            $guardian_id++;
        }
        $students{$old_id} = \%student_hash;
        $student_id++;
    }
}

close(STUDENTS);

insert_data_into_table("san_subjects", \%lessons, "insert_san_subjects.sql");
insert_data_into_table("academic_years", \%academic_years, "insert_academic_years.sql");
insert_data_into_table("groups", \%groups, "insert_groups.sql");
insert_data_into_table("san_semesters", \%semesters, "insert_san_semesters.sql");
insert_data_into_table("semester_subjects", \%semester_lessons, "insert_semester_subjects.sql");
insert_data_into_table("students", \%students, "insert_students.sql");
insert_data_into_table("guardians", \%guardians, "insert_guardians.sql");

sub insert_data_into_table {
    my ($table_name, $data_ref, $file_name) = @_;

    open(SQL, ">$file_name") or die("Cannot open $file_name for writing.\n");

    foreach my $entry_id (keys %$data_ref) {
        if ($data_ref->{$entry_id}->{'id'}) {
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
            if ($val) {
                if (($val =~ /STR_TO_DATE/) or ($val =~ "TRUE") or ($val =~ "FALSE") or ($val =~ 'null')) {
                    print SQL "$val";
                }
                elsif ($val =~ /NULL/i) {
                    print SQL "null";
                }
                else {
                    print SQL "\'$val\'";
                }
                if ($ind<$n_fields) {
                    print SQL ",";
                }
            }
            else {
                print SQL "null";
                if ($ind<$n_fields) {
                    print SQL ",";
                }
            }
            $ind++;
        }
        print SQL ");\n";
    }
    }
    close(SQL);
}

