module arc.x.blaze.common.TArray;

private {

    template isCallableType( T ) {
        const bool isCallableType = is( T == function )             ||
        is( typeof(*T) == function )    ||
        is( T == delegate )             ||
        is( typeof(T.opCall) == function );
    }
    struct IsEqual( T ) {
        static bool opCall( T p1, T p2 ) {
            // TODO: Fix this if/when opEquals is changed to return a bool.
            static if ( is( T == class ) || is( T == struct ) )
                return (p1 == p2) != 0;
            else
                return p1 == p2;
        }
    }

    template ElemTypeOf( T ) {
        alias typeof(T[0]) ElemTypeOf;
    }
}

template find_( Elem, Pred = IsEqual!(Elem) ) {

    static assert( isCallableType!(Pred) );


    size_t fn( Elem[] buf, Elem pat, Pred pred = Pred.init ) {
        foreach( size_t pos, Elem cur; buf ) {
            if ( pred( cur, pat ) )
                return pos;
        }
        return buf.length;
    }


    size_t fn( Elem[] buf, Elem[] pat, Pred pred = Pred.init ) {
        if ( buf.length == 0 ||
                pat.length == 0 ||
                buf.length < pat.length ) {
            return buf.length;
        }

        size_t end = buf.length - pat.length + 1;

        for ( size_t pos = 0; pos < end; ++pos ) {
            if ( pred( buf[pos], pat[0] ) ) {
                size_t mat = 0;

                do {
                    if ( ++mat >= pat.length )
                        return pos - pat.length + 1;
                    if ( ++pos >= buf.length )
                        return buf.length;
                } while ( pred( buf[pos], pat[mat] ) );
                pos -= mat;
            }
        }
        return buf.length;
    }
}


template find( Buf, Pat ) {
    size_t find( Buf buf, Pat pat ) {
        return find_!(ElemTypeOf!(Buf)).fn( buf, pat );
    }
}

template find( Buf, Pat, Pred ) {
    size_t find( Buf buf, Pat pat, Pred pred ) {
        return find_!(ElemTypeOf!(Buf), Pred).fn( buf, pat, pred );
    }
}

template contains( Buf, Pat ) {
    size_t contains( Buf buf, Pat pat ) {
        return find( buf, pat ) != buf.length;
    }
}

template contains( Buf, Pat, Pred ) {
    size_t contains( Buf buf, Pat pat, Pred pred ) {
        return find( buf, pat, pred ) != buf.length;
    }
}
//}
