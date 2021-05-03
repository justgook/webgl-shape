module WebGL.Shape2d.Internal exposing (applyOZ, createTrans, setAlpha)

import Math.Vector3 exposing (Vec3)
import Math.Vector4 exposing (Vec4)
import WebGL.Shape2d.Internal.Transformation as Trans exposing (Transformation)
import WebGL.Shape2d.Shape exposing (Shape)


createTrans : Float -> Float -> Float -> Float -> Float -> Transformation -> Transformation
createTrans tx ty sx_ sy_ a_ parent =
    Trans.create tx ty sx_ sy_ a_
        |> Trans.apply parent


applyOZ : Float -> Float -> Shape a -> Shape a
applyOZ o z shape_ =
    { shape_ | o = o * shape_.o, z = z + shape_.z }


{-| Update alpha channel of vec4 color
-}
setAlpha : Vec3 -> Float -> Vec4
setAlpha =
    Math.Vector3.toRecord >> (\a -> Math.Vector4.vec4 a.x a.y a.z)
