#!/bin/bash

version=$1
script=$(realpath $0)
work_folder=$(dirname $script)

if [[ $version == "" ]]
then
	echo "Please, provide a python version (i.e. 3.6.0)"
else
	if [[ $version =~ ^[1-3]+\.[0-9]+\.[0-9]+ ]]
	then
		continue="YES"
	else
		echo $version is not a valid version
                continue="NO"
	fi
fi

if [[ $continue == "YES" ]]
then

	test_version=$(curl https://www.python.org/ftp/python/$version/ | grep "404 Not Found")

	if [[ $test_version == "" ]]
	then
		continue="YES"
	else
		continue="NO"
		echo "Version "$version" doesn't exists"
	fi
fi

if [[ $continue == "YES" ]]
then
	python_name="Python-"$version
	curl https://www.python.org/ftp/python/$version/$python_name.tgz --output $work_folder/$python_name.tgz

	execution_status=$?
	if [ $execution_status -eq 1 ]
	then
		echo "Download of $python_name failed"
		exit $execution_status
	fi

	tar xvf $work_folder/$python_name.tgz -C $work_folder

	if [ -d $work_folder/$version ]
	then
		continue="NO"
		check=0
		echo "Python $version already installed. Do you want to overwrite it?(Y/N/y/n)"
		read continue

		while [ 3 -gt $check ]
		do
			if [[ $continue == "Y" ]] || [[ $continue == "y" ]]
			then
				let check=4
				rm -rf $work_folder/$version/*
				continue="YES"
			elif [[ $continue == "N" ]] || [[ $continue == "n" ]]
			then
				continue="NO"
				let check=4
			else
				(( check += 1 ))

        	                echo "Not a valid options: $continue"

				if [[ $check -eq 3 ]]
				then
					echo "Python $version already installed. Do you want to overwrite it?\nLast try before exit (Y/N/y/n)"
					read continue

					if [[ $continue == "Y" ]] || [[ $continue == "y" ]] || [[ $continue == "N" ]] || [[ $continue == "n" ]]
					then
						(( check -= 1 ))
					else
						continue="NO"
						(( check += 1 ))
					fi

				else
                                	echo "Python $version already installed. Do you want to overwrite it?(Y/N/y/n)"
					read continue
				fi

			fi
		done

		if [[ $continue == "NO" ]]
		then
			echo "Removing files...."
			rm -rf $work_folder/$python_name
			rm $work_folder/$python_name.tgz
			echo "Exiting...."
			exit 0
		fi

	else
		mkdir -p $work_folder/$version
	fi

	(cd $work_folder/$python_name && ./configure --prefix=$work_folder/$version)

        execution_status=$?
        if [ $execution_status -eq 1 ]
        then
                echo "Command Failed: ./configure --prefix=$work_folder/$version"

		rm -rf $work_folder/$python_name
		rm $work_folder/$python_name.tgz

		check_python_folder=$(ls $work_folder/$version)

		if [[ $check_python_folder == "" ]]
		then
			rm -rf $work_folder/$version
		else
			echo "Another Python $version is installed, keeping the files"
		fi

                exit $execution_status
        fi

	make -C $work_folder/$python_name

        execution_status=$?

        if [ $execution_status -eq 1 ]
        then
                echo "Command Failed: make -C $work_folder/$python_name"
		rm $work_folder/$python_name.tgz
		rm -rf $work_folder/$python_name
                exit $execution_status
        fi

	make install -C $work_folder/$python_name

        execution_status=$?

        if [ $execution_status -eq 1 ]
        then
                echo "Command Failed: make install -C $work_folder/$python_name"
		rm -rf $work_folder/$python_name
		rm $work_folder/$python_name.tgz
                exit $execution_status
        fi

	rm -rf $work_folder/$python_name
	rm $work_folder/$python_name.tgz

	sudo ln -s $work_folder/$version/bin/$(ls $work_folder/$version/bin/ | grep python | grep -v "-" | grep "\.") /opt/usr/local/bin/python$version
fi
