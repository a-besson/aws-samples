
echo:
	echo "Choose one of the following options"

init:
	terraform -chdir=./vpc init; terraform -chdir=./vpc apply --auto-approve;

db:
	terraform -chdir=./aurora-pg init; terraform -chdir=./aurora-pg apply --auto-approve;

clean:
	terraform -chdir=./aurora-pg init; terraform -chdir=./aurora-pg destroy --auto-approve;
	terraform -chdir=./vpc init; terraform -chdir=./vpc destroy --auto-approve;