module WebGL.Game2d.Util exposing (size)

{-|

@docs size

-}

import Math.Vector2 exposing (Vec2, vec2)
import WebGL.Texture exposing (Texture)


{-| Get texture size as Math.Vec2
-}
size : Texture -> Vec2
size t =
    WebGL.Texture.size t |> (\( w, h ) -> vec2 (toFloat w) (toFloat h))
