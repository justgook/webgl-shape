module WebGL.Game2d.TextureManager exposing (TextureManager, empty, request, update)

{-|


# Texture Manager

@docs TextureManager, empty, request, update

-}

import Dict exposing (Dict)
import Set exposing (Set)
import Task exposing (Task)
import WebGL.Texture as Texture exposing (Error, Texture)


{-| -}
type alias TextureManager =
    { done : Dict String Texture
    , loading : Set String
    , missing : Set String
    }


{-| -}
empty : TextureManager
empty =
    { done = Dict.empty
    , loading = Set.empty
    , missing = Set.empty
    }


{-| -}
update : Result ( String, Texture.Error ) ( String, Texture ) -> TextureManager -> TextureManager
update r ({ done, loading } as textures) =
    case r of
        Ok ( name, t ) ->
            { textures
                | done = Dict.insert name t done
                , loading = Set.remove name loading
            }

        Err ( name, err ) ->
            textures


{-| -}
request : TextureManager -> ( TextureManager, Task Error (List Texture) )
request textures =
    let
        ( tt, tasks ) =
            Set.foldl
                (\src (( l, req ) as acc) ->
                    if Set.member src textures.loading then
                        acc

                    else
                        ( Set.insert src l, Texture.load src :: req )
                )
                ( textures.loading, [] )
                textures.missing
    in
    ( { textures
        | missing = Set.empty
        , loading = tt
      }
    , Task.sequence tasks
    )
