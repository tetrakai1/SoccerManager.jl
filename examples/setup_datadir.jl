using SoccerManager

# Copy default roster/etc files from package into chosen data directory
# The directory will be created if it doesn't exist or can be overwritten by setting force = true
# WARNING: Overwriting the directory will delete all the contents
path_datadir = "/home/user1/Documents/SoccerManager"
paths        = init_user_data_dir(path_datadir, force = false);

# Save the path for use by the other example scripts
write("examples/path_datadir.txt", path_datadir)
