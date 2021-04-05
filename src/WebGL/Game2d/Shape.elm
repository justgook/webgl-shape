module WebGL.Game2d.Shape exposing (Shape, create, ShapeData, GroupData, TexturedData)

{-|


# Shape

@docs Shape, create, ShapeData, GroupData, TexturedData

-}

import WebGL.Texture exposing (Texture)


{-| Helper function to create [`Shape`](#Shape) from render
-}
create : a -> Shape a
create data =
    { x = 0
    , y = 0
    , z = 0
    , a = 0
    , sx = 1
    , sy = 1
    , o = 1
    , data = data
    }


{-| Shapes help you make a game elements.

Read on to see examples of [`circle`](#circle), [`rectangle`](#rectangle),
[`words`](#words), [`image`](#image), and many more!

-}
type alias Shape a =
    { x : Float
    , y : Float
    , z : Float -- Z - index
    , a : Float -- Angle
    , sx : Float
    , sy : Float
    , o : Float
    , data : a
    }


{-| -}
type alias ShapeData render =
    { width : Float, height : Float, render : render }


{-| -}
type alias GroupData shape =
    List shape


{-| -}
type alias TexturedData key shape =
    { src : key, fn : Texture -> shape }
