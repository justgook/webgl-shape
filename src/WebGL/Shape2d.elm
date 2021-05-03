module WebGL.Shape2d exposing
    ( view, update, Model
    , move, setZ
    , rotate, fade, scale
    , TextureManager, textureManager
    , Computer
    , Time, tick
    , Mouse, initMouse, mouseSubscription
    , Screen, toScreen, resize, requestScreen
    , Keyboard, initKeyboard, keyboardSubscription, toX, toY, toXY
    , Color, rgb
    )

{-|


# Application

@docs view, update, Model


# Move Shapes

@docs move, setZ


# Customize Shapes

@docs rotate, fade, scale


# Texture Manager

@docs TextureManager, textureManager


# Computer

@docs Computer


## Time

@docs Time, tick


## Mouse

@docs Mouse, initMouse, mouseSubscription


## Screen

@docs Screen, toScreen, resize, requestScreen


## Keyboard

@docs Keyboard, initKeyboard, keyboardSubscription, toX, toY, toXY


# Colors

@docs Color, rgb

-}

import Browser.Dom as Dom
import Browser.Events as E
import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes as H
import Html.Lazy
import Json.Decode as D
import Math.Vector3
import Set exposing (Set)
import Task
import Time
import WebGL exposing (Entity)
import WebGL.Shape2d.Render exposing (Height, Width)
import WebGL.Shape2d.Shape exposing (Shape)
import WebGL.Shape2d.TexturedShape as AutoTextures exposing (TextureLoader(..), TexturedShape)
import WebGL.Texture as Texture exposing (Texture)


{-| -}
type alias TextureManager =
    TextureLoader String


textureManager_ : Dict String Texture -> Set String -> Set String -> TextureLoader String
textureManager_ dict missing loading =
    TextureLoader
        { get = \k -> Dict.get k dict
        , missing = \k -> textureManager_ dict (Set.insert k missing) loading
        , extract =
            \() ->
                let
                    ( tt, tasks ) =
                        Set.foldl
                            (\src (( l, req ) as acc) ->
                                if Set.member src loading then
                                    acc

                                else
                                    ( Set.insert src l, src :: req )
                            )
                            ( loading, [] )
                            missing
                in
                ( textureManager_ dict Set.empty tt, tasks )
        , insert =
            \key tt ->
                textureManager_ (Dict.insert key tt dict) missing loading
        }


{-| -}
textureManager : TextureManager
textureManager =
    textureManager_ Dict.empty Set.empty Set.empty


{-| -}
type alias Model screen a =
    { a
        | screen : { screen | width : Width, height : Height }
        , textures : TextureManager
        , entities : List Entity
    }


type alias Message screen a =
    Model screen a -> Model screen a


{-| Create WebGL canvas
-}
view : { a | screen : { screen | width : Width, height : Height }, entities : List Entity } -> Html msg
view model =
    view_
        [ H.attribute "style" "position:absolute;top:0;right:0;bottom:0;left:0;"
        , H.height (round model.screen.height)
        , H.width (round model.screen.width)
        ]
        model.entities


view_ : List (Html.Attribute msg) -> List Entity -> Html msg
view_ attrs entities =
    Html.Lazy.lazy3 WebGL.toHtmlWith webGLOption attrs entities


webGLOption : List WebGL.Option
webGLOption =
    [ WebGL.alpha False, WebGL.depth 1, WebGL.clearColor 1 1 1 1 ]



{- UPDATE -}


textureOption : Texture.Options
textureOption =
    { magnify = Texture.linear
    , minify = Texture.linear
    , horizontalWrap = Texture.clampToEdge
    , verticalWrap = Texture.clampToEdge
    , flipY = True
    }


load : String -> Task.Task Texture.Error ( String, Texture )
load src =
    Texture.loadWith textureOption src
        |> Task.map (\t -> ( src, t ))


{-| -}
update : (Model screen a -> List (TexturedShape String)) -> Message screen a -> Model screen a -> ( Model screen a, Cmd (Message screen a) )
update viewFn msg oldModel =
    let
        updatedModel =
            msg oldModel

        ( entities, TextureLoader textures ) =
            viewFn updatedModel
                |> AutoTextures.toEntities updatedModel.screen updatedModel.textures

        ( loader, missing ) =
            textures.extract ()

        cmd2 =
            case missing of
                [] ->
                    Cmd.none

                _ ->
                    List.map load missing
                        |> Task.sequence
                        |> Task.attempt
                            (\r m ->
                                case r of
                                    Ok value ->
                                        { m | textures = List.foldl (\( k, v ) (TextureLoader acc) -> acc.insert k v) m.textures value }

                                    Err err ->
                                        m
                            )
    in
    ( { updatedModel
        | entities = entities
        , textures = loader
      }
    , cmd2
    )


{-| Move a shape by some Float of pixels:

    import Playground exposing (..)

    main =
        picture
            [ square red 100
                |> move -60 60
            , square yellow 100
                |> move 60 60
            , square green 100
                |> move 60 -60
            , square blue 100
                |> move -60 -60
            ]

-}
move : Float -> Float -> Shape a -> Shape a
move dx dy ({ x, y } as shape) =
    { shape | x = x + dx, y = y + dy }


{-| The `setZ` specifies the stack order of a shapes.

A shape with greater stack order is always in front of an element with a lower stack order.

**Note:** be aware z-indexing will mess up semi-transparent shapes,
if you need both (z ordering and semi-transparency) better sort shapes.

-}
setZ : Int -> Shape a -> Shape a
setZ z shape =
    { shape | z = toFloat z }


{-| Make a shape bigger or smaller. So if you wanted some [`words`](#words) to
be larger, you could say:

    import Playground exposing (..)

    main =
        picture
            [ words black "Hello, nice to see you!"
                |> scale 3 3
            ]

-}
scale : Float -> Float -> Shape a -> Shape a
scale sx sy shape =
    { shape | sx = shape.sx * sx, sy = shape.sy * sy }


{-| Rotate shapes in degrees.

    import Playground exposing (..)

    main =
        picture
            [ words black "These words are tilted!"
                |> rotate 10
            ]

The degrees go _counter-clockwise_ to match the direction of the
[unit circle](https://en.wikipedia.org/wiki/Unit_circle).

-}
rotate : Float -> Shape a -> Shape a
rotate da ({ x, y, a, sx, sy, o, data } as shape) =
    { shape | a = a + degrees da }


{-| Fade a shape. This lets you make shapes see-through or even completely
invisible. Here is a shape that fades in and out:

    import Playground exposing (..)

    main =
        animation view

    view time =
        [ square orange 30
        , square blue 200
            |> fade (zigzag 0 1 3 time)
        ]

The Float has to be between `0` and `1`, where `0` is totally transparent
and `1` is completely solid.

-}
fade : Float -> Shape a -> Shape a
fade o shape =
    { shape | o = o }


{-| When writing a [`game`](#game), you can look up all sorts of information
about your computer:

  - [`Mouse`](#Mouse) - Where is the mouse right now?
  - [`Keyboard`](#Keyboard) - Are the arrow keys down?
  - [`Screen`](#Screen) - How wide is the screen?
  - [`Time`](#Time) - What time is it right now?

So you can use expressions like `computer.mouse.x` and `computer.keyboard.enter`
in games where you want some mouse or keyboard interaction.

-}
type alias Computer =
    { mouse : Mouse
    , keyboard : Keyboard
    , screen : Screen
    , time : Time
    }


{-| The current time.

Helpful when making an [`animation`](#animation) with functions like
[`spin`](#spin), [`wave`](#wave), and [`zigzag`](#zigzag).

`Time` is defined as:

    type alias Time =
        { now : Int
        , delta : Int
        }

Where `now` is the number of milliseconds since 1970 January 1 at 00:00:00 UTC,
and `delta` is the number of milliseconds since the previous animation frame.

-}
type alias Time =
    { now : Int, delta : Int }


{-| -}
tick : Sub (Time -> Time)
tick =
    E.onAnimationFrame
        (\nowPosix was ->
            let
                now =
                    Time.posixToMillis nowPosix
            in
            { now = now, delta = now - was.now }
        )


{-| Figure out what is going on with the mouse.

You could draw a circle around the mouse with a program like this:

    import Playground exposing (..)

    main =
        game view update 0

    view computer memory =
        [ circle yellow 40
            |> moveX computer.mouse.x
            |> moveY computer.mouse.y
        ]

    update computer memory =
        memory

You could also use `computer.mouse.down` to change the color of the circle
while the mouse button is down.

-}
type alias Mouse =
    { x : Float
    , y : Float
    , down : Bool
    }


{-| -}
initMouse : Mouse
initMouse =
    Mouse 0 0 False


{-| -}
mouseSubscription : Sub (Mouse -> Mouse)
mouseSubscription =
    Sub.batch
        [ E.onMouseDown (D.succeed (\mouse -> { mouse | down = True }))
        , E.onMouseUp (D.succeed (\mouse -> { mouse | down = False }))
        , E.onMouseMove (D.map2 (\x y mouse -> { mouse | x = x, y = y }) (D.field "pageX" D.float) (D.field "pageY" D.float))
        ]


{-| Get the dimensions of the screen. If the screen is 800 by 600, you will see
a value like this:

    { width = 800
    , height = 600
    , top = 300
    , left = -400
    , right = 400
    , bottom = -300
    }

This can be nice when used with [`moveY`](#moveY) if you want to put something
on the bottom of the screen, no matter the dimensions.

-}
type alias Screen =
    { width : Float
    , height : Float
    , top : Float
    , left : Float
    , right : Float
    , bottom : Float
    }


{-| -}
toScreen : Float -> Float -> Screen
toScreen width height =
    { width = width
    , height = height
    , top = height / 2
    , left = -width / 2
    , right = width / 2
    , bottom = -height / 2
    }


{-| -}
resize : Sub Screen
resize =
    E.onResize (\w h -> toScreen (toFloat w) (toFloat h))


{-| -}
requestScreen : Cmd ({ b | screen : Screen } -> { b | screen : Screen })
requestScreen =
    Dom.getViewport
        |> Task.map
            (\{ scene } model -> { model | screen = toScreen scene.width scene.height })
        |> Task.attempt (Result.withDefault identity)


{-| Figure out what is going on with the keyboard.

If someone is pressing the UP and RIGHT arrows, you will see a value like this:

    { up = True
    , down = False
    , left = False
    , right = True
    , space = False
    , enter = False
    , shift = False
    , backspace = False
    , keys = Set.fromList [ "ArrowUp", "ArrowRight" ]
    }

So if you want to move a character based on arrows, you could write an update
like this:

    update computer y =
        if computer.keyboard.up then
            y + 1

        else
            y

Check out [`toX`](#toX) and [`toY`](#toY) which make this even easier!

**Note:** The `keys` set will be filled with the `code` of all keys which are
down right now. So you will see things like `"KeyA"`, `"KeyB"`, `"KeyC"`, `"Digit1"`, `"Digit2"`,
`"Space"`, and `"ControlLeft"` in there.
For example, the code is `"KeyQ"` for the `Q` key on a QWERTY layout keyboard,
but the same code value also represents the `'` key on Dvorak keyboards and the `A` key on AZERTY keyboards.

Check out [this list][list] to see the
names used for all the different keys! From there, you can use
[`Set.member`][member] to check for whichever key you want. E.g.
`Set.member "Control" computer.keyboard.keys`.

[list]: https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/code/code_values
[member]: /packages/elm/core/latest/Set#member

-}
type alias Keyboard =
    { up : Bool
    , down : Bool
    , left : Bool
    , right : Bool
    , space : Bool
    , enter : Bool
    , shift : Bool
    , backspace : Bool
    , keys : Set.Set String
    }


{-| -}
initKeyboard : Keyboard
initKeyboard =
    { up = False
    , down = False
    , left = False
    , right = False
    , space = False
    , enter = False
    , shift = False
    , backspace = False
    , keys = Set.empty
    }


{-| -}
keyboardSubscription : Sub (Keyboard -> Keyboard)
keyboardSubscription =
    Sub.batch
        [ E.onKeyUp (D.map (\key keyboard -> updateKeyboard False key keyboard) (D.field "code" D.string))
        , E.onKeyDown
            (D.field "repeat" D.bool
                |> D.andThen
                    (\repeat ->
                        if repeat then
                            D.fail ""

                        else
                            D.field "code" D.string
                                |> D.map
                                    (\key keyboard ->
                                        updateKeyboard True key keyboard
                                    )
                    )
            )
        ]


updateKeyboard : Bool -> String -> Keyboard -> Keyboard
updateKeyboard isDown key keyboard =
    let
        keys =
            if isDown then
                Set.insert key keyboard.keys

            else
                Set.remove key keyboard.keys
    in
    case key of
        "Space" ->
            { keyboard | keys = keys, space = isDown }

        "Enter" ->
            { keyboard | keys = keys, enter = isDown }

        "ShiftLeft" ->
            { keyboard | keys = keys, shift = isDown }

        "ShiftRight" ->
            { keyboard | keys = keys, shift = isDown }

        "Backspace" ->
            { keyboard | keys = keys, backspace = isDown }

        "ArrowUp" ->
            { keyboard | keys = keys, up = isDown }

        "ArrowDown" ->
            { keyboard | keys = keys, down = isDown }

        "ArrowLeft" ->
            { keyboard | keys = keys, left = isDown }

        "ArrowRight" ->
            { keyboard | keys = keys, right = isDown }

        _ ->
            { keyboard | keys = keys }


{-| Turn the LEFT and RIGHT arrows into a Float.

    toX { left = False, right = False, ... } == 0
    toX { left = True , right = False, ... } == -1
    toX { left = False, right = True , ... } == 1
    toX { left = True , right = True , ... } == 0

So to make a square move left and right based on the arrow keys, we could say:

    import Playground exposing (..)

    main =
        game view update 0

    view computer x =
        [ square green 40
            |> moveX x
        ]

    update computer x =
        x + toX computer.keyboard

-}
toX : Keyboard -> Float
toX keyboard =
    (if keyboard.right then
        1

     else
        0
    )
        - (if keyboard.left then
            1

           else
            0
          )


{-| Turn the UP and DOWN arrows into a Float.

    toY { up = False, down = False, ... } == 0
    toY { up = True , down = False, ... } == 1
    toY { up = False, down = True , ... } == -1
    toY { up = True , down = True , ... } == 0

This can be used to move characters around in games just like [`toX`](#toX):

    import Playground exposing (..)

    main =
        game view update ( 0, 0 )

    view computer ( x, y ) =
        [ square blue 40
            |> move x y
        ]

    update computer ( x, y ) =
        ( x + toX computer.keyboard
        , y + toY computer.keyboard
        )

-}
toY : Keyboard -> Float
toY keyboard =
    (if keyboard.up then
        1

     else
        0
    )
        - (if keyboard.down then
            1

           else
            0
          )


{-| If you just use `toX` and `toY`, you will move diagonal too fast. You will go
right at 1 pixel per update, but you will go up/right at 1.41421 pixels per
update.

So `toXY` turns the arrow keys into an `(x,y)` pair such that the distance is
normalized:

    toXY { up = True , down = False, left = False, right = False, ... } == (1, 0)
    toXY { up = True , down = False, left = False, right = True , ... } == (0.707, 0.707)
    toXY { up = False, down = False, left = False, right = True , ... } == (0, 1)

Now when you go up/right, you are still going 1 pixel per update.

    import Playground exposing (..)

    main =
        game view update ( 0, 0 )

    view computer ( x, y ) =
        [ square green 40
            |> move x y
        ]

    update computer ( x, y ) =
        let
            ( dx, dy ) =
                toXY computer.keyboard
        in
        ( x + dx, y + dy )

-}
toXY : Keyboard -> ( Float, Float )
toXY keyboard =
    let
        x =
            toX keyboard

        y =
            toY keyboard
    in
    if x /= 0 && y /= 0 then
        ( x / squareRootOfTwo, y / squareRootOfTwo )

    else
        ( x, y )


squareRootOfTwo : Float
squareRootOfTwo =
    sqrt 2


{-| Represents a color.

The colors below, like `red` and `green`, come from the [Tango palette][tango].
It provides a bunch of aesthetically reasonable colors. Each color comes with a
light and dark version, so you always get a set like `lightYellow`, `yellow`,
and `darkYellow`.

[tango]: https://en.wikipedia.org/wiki/Tango_Desktop_Project

-}
type alias Color =
    Math.Vector3.Vec3



-- CUSTOM COLORS


{-| RGB stands for Red-Green-Blue. With these three parts, you can create any
color you want. For example:

    brightBlue =
        rgb 18 147 216

    brightGreen =
        rgb 119 244 8

    brightPurple =
        rgb 94 28 221

Each Float needs to be between 0 and 255.

It can be hard to figure out what Floats to pick, so try using a color picker
like [paletton] to find colors that look nice together. Once you find nice
colors, click on the color previews to get their RGB values.

[paletton]: http://paletton.com/

-}
rgb : Float -> Float -> Float -> Color
rgb r g b =
    Math.Vector3.vec3 (toFloat (colorClamp r) / 255) (toFloat (colorClamp g) / 255) (toFloat (colorClamp b) / 255)


colorClamp : Float -> Int
colorClamp n =
    clamp 0 255 (round n)
