#! /bin/bash

working_dir=$(pwd)

init_params ()
{
	project_root_dir=${working_dir}/.vcproj/
	project_file=${project_root_dir}/vc.proj	# File that stores the setting of VCProj
	project_files=${project_root_dir}/project_files	# Store all the files included in the project
	file_name_wildcard=""
	options="egh"
}

print_usage ()
{
cat << EOT
	$(basename $0) -[$options]
		e : open program entry
		b : build the project
		g : generate symbol database
		h : print help message
EOT
}

open_program_entry ()
{
	echo "Open ${working_dir}/${program_entry}"
	vim ${working_dir}/${program_entry}
}

generate_symbol_database ()
{
	[ -f $project_files ] && rm -v $project_files

	generate_name_wildcard

	for path in ${component_paths[@]};do
		generate_db_for_a_path $path
	done

	echo "Generating cscope.out"
	cscope -b -q -P${working_dir} -i$project_files

	echo "Generating tags"
	ctags --c++-kinds=+p --fields=+iaS --extra=+q -L $project_files
}

generate_name_wildcard ()
{
	local first_name_type=true

	for ft in ${file_type[@]};do
		if $first_name_type;then
			file_name_wildcard="-name $ft"

			first_name_type=false
		else
			file_name_wildcard="$file_name_wildcard -o -name $ft"
		fi
	done

	echo "File name wildcard is $file_name_wildcard"
}

generate_db_for_a_path ()
{
	if [ $# -ne 1 ];then
		echo "Invalid param numbers $#! Should be 1."
	fi

	local absolute_path=${working_dir}/${1}

	#TODO: Should we put the project_files into project_root_dir
	echo $project_files
	find $absolute_path $file_name_wildcard >> $project_files
}

build_project ()
{
	echo "Build(using configuration $1)"
	#TODO: Check input params 
	eval "${build_commands[$1]}"
}

deploy_project ()
{
	echo "Deploy"
	#TODO: Maybe one day we will support multiple deploy commands
	eval "${deploy_commands[0]}"
}

# Main
init_params

#TODO: Use a function to source the file
source $project_file

while getopts 'egb:dVhH' c
do
	case $c in
		e) open_program_entry
			;;
		g) generate_symbol_database
			;;
		b) build_project $OPTARG
			;;
		d) deploy_project
			;;
		h) print_usage
			;;
		*) print_usage
			;;
	esac
done

[ $? -ne 0 ] && echo "No args"

exit 0
