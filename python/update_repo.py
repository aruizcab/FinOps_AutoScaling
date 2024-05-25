import base64
from github import Github
from github import InputGitTreeElement
import os


# Parameters 
# user = os.environ["USERNAME"]                     # github user name
user = "aruizcab"                                   # github user name
url = f"https://api.github.com/users/{user}"        # url to request
password = os.environ["TF_VAR_GH_TOKEN"]               # github token
repo = "FinOps_AutoScaling"                         # repository name
# repo = os.environ["REPOSITORY"]                     # repository name
target_branch = "main"                              # branch to update
file_list = [                                      # list with the paths of the files that will be updated
    "./python/config.json",
    "./terraform/compute.tf"
]
file_names = [
    'config.json',
    'compute.tf'
]

g = Github(user,password)
repo = g.get_user().get_repo(repo) # repo name

commit_message = 'auto-update scale-set'
main_ref = repo.get_git_ref('heads/main')
main_sha = main_ref.object.sha
base_tree = repo.get_git_tree(main_sha)

element_list = list()
for i, entry in enumerate(file_list):
    with open(entry) as input_file:
        data = input_file.read()
    element = InputGitTreeElement(file_names[i], '100644', 'blob', data)
    element_list.append(element)

tree = repo.create_git_tree(element_list, base_tree)
parent = repo.get_git_commit(main_sha)
commit = repo.create_git_commit(commit_message, tree, [parent])
main_ref.edit(commit.sha)