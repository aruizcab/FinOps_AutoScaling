from github import Github
from github import InputGitTreeElement
import os


# parameters 
action = os.environ["ACTION"]                       # action that will be executed
# user = os.environ["USERNAME"]                     # github user name
user = "aruizcab"                                   # github user name
url = f"https://api.github.com/users/{user}"        # url to request
password = os.environ["TF_VAR_GH_TOKEN"]            # github token
# repo = os.environ["REPOSITORY"]                   # repository name
repo = "FinOps_AutoScaling"                         # repository name
target_branch = "main"                              # branch to update
file_list = [                                       # list with the paths of the files that will be updated
    "python/config.json",
    "terraform/compute.tf"
]


# login to github
g = Github(user,password)
# get target repository
repo = g.get_user().get_repo(repo) # repo name

commit_message = f'auto-update: {action}'

# get target branch reference (main)
main_ref = repo.get_git_ref('heads/main')
# get target branch sha (main)
main_sha = main_ref.object.sha
# get target branch tree (main)
base_tree = repo.get_git_tree(main_sha)

# obtain target files tree element
element_list = list()
for i, entry in enumerate(file_list):
    with open(entry) as input_file:
        data = input_file.read()
    element = InputGitTreeElement(file_list[i], '100644', 'blob', data)
    element_list.append(element)

# create git tree
tree = repo.create_git_tree(element_list, base_tree)
# obtain git commit
parent = repo.get_git_commit(main_sha)
# create new commit with defined tree
commit = repo.create_git_commit(commit_message, tree, [parent])
# push new commit to remote
main_ref.edit(commit.sha)