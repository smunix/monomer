{-# LANGUAGE ExistentialQuantification #-}

module Monomer.Widget.BaseWidget (
  createWidget,
  widgetMerge
) where

import Control.Monad
import Data.Default
import Data.Maybe
import Data.Typeable (Typeable, cast)

import Monomer.Common.Geometry
import Monomer.Common.Tree
import Monomer.Event.Types
import Monomer.Graphics.Renderer
import Monomer.Widget.WidgetContext
import Monomer.Widget.Types
import Monomer.Widget.Util

type WidgetMergeHandler s e = WidgetEnv s e -> WidgetContext -> Maybe WidgetState -> WidgetInstance s e -> WidgetResult s e

createWidget :: Widget s e
createWidget = Widget {
  _widgetInit = defaultInit,
  _widgetGetState = defaultGetState,
  _widgetMerge = widgetMerge defaultMerge,
  _widgetNextFocusable = defaultNextFocusable,
  _widgetFind = defaultFind,
  _widgetHandleEvent = defaultHandleEvent,
  _widgetHandleMessage = defaultHandleMessage,
  _widgetPreferredSize = defaultPreferredSize,
  _widgetResize = defaultResize,
  _widgetRender = defaultRender
}

defaultInit :: WidgetEnv s e -> WidgetContext -> WidgetInstance s e -> WidgetResult s e
defaultInit _ _ widgetInstance = resultWidget widgetInstance

defaultGetState :: WidgetEnv s e -> Maybe WidgetState
defaultGetState _ = Nothing

defaultMerge :: WidgetEnv s e -> WidgetContext -> Maybe WidgetState -> WidgetInstance s e -> WidgetResult s e
defaultMerge wenv ctx oldState newInstance = resultWidget newInstance

widgetMerge :: WidgetMergeHandler s e -> WidgetEnv s e -> WidgetContext -> WidgetInstance s e -> WidgetInstance s e -> WidgetResult s e
widgetMerge mergeHandler wenv ctx oldInstance newInstance = result where
  oldState = _widgetGetState (_instanceWidget oldInstance) wenv
  result = mergeHandler wenv ctx oldState newInstance

defaultNextFocusable :: WidgetEnv s e -> WidgetContext -> WidgetInstance s e -> Maybe Path
defaultNextFocusable wenv ctx widgetInstance = Nothing

defaultFind :: WidgetEnv s e -> Path -> Point -> WidgetInstance s e -> Maybe Path
defaultFind wenv path point widgetInstance = Just $ _instancePath widgetInstance

defaultHandleEvent :: WidgetEnv s e -> WidgetContext -> SystemEvent -> WidgetInstance s e -> Maybe (WidgetResult s e)
defaultHandleEvent wenv ctx evt widgetInstance = Nothing

defaultHandleMessage :: forall i s e m . Typeable i => WidgetEnv s e -> WidgetContext -> i -> WidgetInstance s e -> Maybe (WidgetResult s e)
defaultHandleMessage wenv ctx evt widgetInstance = Nothing

defaultPreferredSize :: WidgetEnv s e -> WidgetInstance s e -> Tree SizeReq
defaultPreferredSize wenv widgetInstance = singleNode SizeReq {
  _sizeRequested = Size 0 0,
  _sizePolicyWidth = FlexibleSize,
  _sizePolicyHeight = FlexibleSize
}

defaultResize :: WidgetEnv s e -> Rect -> Rect -> WidgetInstance s e -> Tree SizeReq -> WidgetInstance s e
defaultResize wenv viewport renderArea widgetInstance reqs = widgetInstance {
    _instanceViewport = viewport,
    _instanceRenderArea = renderArea
  }

defaultRender :: (Monad m) => Renderer m -> WidgetEnv s e -> WidgetContext -> WidgetInstance s e -> m ()
defaultRender renderer wenv ctx widgetInstance = return ()
