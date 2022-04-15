function preferenceFolder_saveTempDir(filename,Data)

username = char(java.lang.System.getProperty('user.name'));

if ismac()
    prefFile = ['/Users/', username, '/Library/Application Support/rpspass/temp'];
else
    prefFile = ['C:\Users\', username, '\AppData\Roaming\FCMPASS\rpspass\temp'];
end

save(fullfile(prefFile,filename),'Data')

end