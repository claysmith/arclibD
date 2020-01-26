set installp=C:\imports\derelict
set libpath=C:\Users\csmith\dmd\windows\lib

mkdir %installp%
copy derelict.lib %libpath%
xcopy derelict\*.* %installp% /E /D /Y
