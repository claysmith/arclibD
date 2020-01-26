echo "Which example?: "
read input

echo "Building $input"
cdc $input.d -I/usr/local/src -L/usr/local/lib/arc.a -L/usr/local/lib/derelict.a
echo "$input built"

