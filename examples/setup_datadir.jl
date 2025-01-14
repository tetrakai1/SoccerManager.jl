using SoccerManager

# Copy default roster/etc files from package into chosen data directory
# The directory will be created if it doesn't exist or can be overwritten by setting force = true
# WARNING: Overwriting the directory will delete all the contents
# A tuple of useful paths is also returned 
path_datadir = "/home/user1/Documents/SoccerManager"
paths        = init_user_data_dir(path_datadir, force = false);
