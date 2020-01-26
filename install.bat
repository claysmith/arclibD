set installp=C:\imports\arc
set libpath=C:\Users\csmith\dmd\windows\lib

mkdir %installp%
copy arc.lib %libpath%
xcopy arc\*.* %installp% /E /D /Y
