# SCP: Secret Laboratory Server Synchronizer
After a series of DDoS attacks against my SCP:SL hub server, I decided to split my SCP:SL game servers into 4 different server hubs so that even if one underwent a DDoS attack, it could be mitigated by redirecting players to other servers, while figuring out how to block the DDoS attack with my host.

However, this led to several issues. Firstly, the config_remoteadmin.txt file was no longer universal across all servers. I had to add moderators and then manually upload the file to every single server. Secondly, and much worse, the ban files across all the servers were no longer synced. It was not a matter of downloading and reuploading them, because they all now had different bans stored in them.

As a solution to this issue, I created a Git repository that would synchronize all of the changes on my servers with each other.

## First Architecture
![First Architecture](https://raw.githubusercontent.com/NobleUplift/SCPSecretLaboratory/master/scpsl_architecture_v1.png "First Architecture")

My first architecture was a hobbyist's foray into Continuous Integration/Continuous Deployment. I wanted to see if I could use the concepts of CI/CD to synchronize my servers with each other. I simply pushed my changes to origin/scpsl*, a GitLab runner would take the changes and merge with master, and then before my next push, I would pull my changes from the now-updated master branch.

**However**, this came at a cost. Being on the free tier of GitLab, the runners could take from 5 minutes to **60 minutes** to complete! It didn't take long for my servers to get more popular and to scale, resulting in more GitLab runners, and more sync issues with the repository. Very soon, this architecture was no longer viable.

## Second Architecture
![Second Architecture](https://raw.githubusercontent.com/NobleUplift/SCPSecretLaboratory/master/scpsl_architecture_v2.png "Second Architecture")

My second architecture required the creaton of a *second* repository on my server in my repository next to each other: `~/.config/SCP Secret Laboratory` and `~/.config/SCPSLConfig` (the latter is the name of the repository in GitLab). The algorithm also became a bit more complicated.

If there are bans/reserved slots/mutes to commit:
1. Commit `~/.config/SCP Secret Laboratory` first
2. Push `~/.config/SCP Secret Laboratory` to origin/scpsl*
3. `~/.config/SCPSLConfig` pulls from origin
4. `~/.config/SCPSLConfig`/master merges with `~/.config/SCPSLConfig`/scpsl*
5. `~/.config/SCP Secret Laboratory` merges with origin/master

If there are not bans/reserved slots/mutes to commit:
1. `~/.config/SCPSLConfig` pulls from origin
2. `~/.config/SCPSLConfig`/master merges with `~/.config/SCPSLConfig`/scpsl*
3. `~/.config/SCP Secret Laboratory` merges with origin/master
