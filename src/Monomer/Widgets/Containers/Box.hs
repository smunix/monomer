{-|
Module      : Monomer.Widgets.Containers.Box
Copyright   : (c) 2018 Francisco Vallarino
License     : BSD-3-Clause (see the LICENSE file)
Maintainer  : fjvallarino@gmail.com
Stability   : experimental
Portability : non-portable

Container for a single item. Useful in different layout situations, since it
provides alignment options. This allows for the inner widget to keep its size
while being positioned more explicitly, while the box takes up the complete
space assigned by the container (in particular for containers which do not
follow SizeReq restriccions, such as Grid).
Can be used to add padding to an inner widget with a border. This is equivalent
to the margin property in CSS.
Also useful to handle click events in complex widget structures (for example, a
label with an image at its side).

Config:

- mergeRequired: function called during merge that receives the old and new
  model, returning True in case the child widget needs to be merged. Since by
  default merge is required, this function can be used to restrict merging when
  it would be expensive and it is not necessary. For example, a list of widgets
  representing search result only needs to be updated when the list of results
  changes, not while the user inputs new search criteria (which also triggers
  a model change and, hence, the merge process).
- ignoreEmptyArea: when the inner widget does not use all the available space,
  ignoring the unassigned space allows for mouse events to pass through. This is
  useful in zstack layers.
- sizeReqUpdater: allows modifying the 'SizeReq' generated by the inner widget.
- alignLeft: aligns the inner widget to the left.
- alignCenter: aligns the inner widget to the horizontal center.
- alignRight: aligns the inner widget to the right.
- alignTop: aligns the inner widget to the top.
- alignMiddle: aligns the inner widget to the left.
- alignBottom: aligns the inner widget to the bottom.
- onClick: click event.
- onClickReq: generates a WidgetRequest on click.
- onClickEmpty: click event on empty area.
- onClickEmptyReq: generates a WidgetRequest on click in empty area.
- expandContent: if the inner widget should use all the available space. To be
  able to use alignment options, this must be False (the default).
-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE RankNTypes #-}

module Monomer.Widgets.Containers.Box (
  BoxCfg(..),
  box,
  box_,
  expandContent
) where

import Control.Applicative ((<|>))
import Control.Lens ((&), (^.), (.~))
import Data.Default
import Data.Maybe

import qualified Data.Sequence as Seq

import Monomer.Widgets.Container
import Monomer.Widgets.Containers.Stack

import qualified Monomer.Lens as L

-- | Configuration options for box widget.
data BoxCfg s e = BoxCfg {
  _boxExpandContent :: Maybe Bool,
  _boxIgnoreEmptyArea :: Maybe Bool,
  _boxSizeReqUpdater :: Maybe SizeReqUpdater,
  _boxMergeRequired :: Maybe (s -> s -> Bool),
  _boxAlignH :: Maybe AlignH,
  _boxAlignV :: Maybe AlignV,
  _boxOnFocusReq :: [Path -> WidgetRequest s e],
  _boxOnBlurReq :: [Path -> WidgetRequest s e],
  _boxOnEnterReq :: [WidgetRequest s e],
  _boxOnLeaveReq :: [WidgetRequest s e],
  _boxOnClickReq :: [WidgetRequest s e],
  _boxOnClickEmptyReq :: [WidgetRequest s e],
  _boxOnBtnPressedReq :: [Button -> Int -> WidgetRequest s e],
  _boxOnBtnReleasedReq :: [Button -> Int -> WidgetRequest s e]
}

instance Default (BoxCfg s e) where
  def = BoxCfg {
    _boxExpandContent = Nothing,
    _boxIgnoreEmptyArea = Nothing,
    _boxSizeReqUpdater = Nothing,
    _boxMergeRequired = Nothing,
    _boxAlignH = Nothing,
    _boxAlignV = Nothing,
    _boxOnFocusReq = [],
    _boxOnBlurReq = [],
    _boxOnEnterReq = [],
    _boxOnLeaveReq = [],
    _boxOnClickReq = [],
    _boxOnClickEmptyReq = [],
    _boxOnBtnPressedReq = [],
    _boxOnBtnReleasedReq = []
  }

instance Semigroup (BoxCfg s e) where
  (<>) t1 t2 = BoxCfg {
    _boxExpandContent = _boxExpandContent t2 <|> _boxExpandContent t1,
    _boxIgnoreEmptyArea = _boxIgnoreEmptyArea t2 <|> _boxIgnoreEmptyArea t1,
    _boxSizeReqUpdater = _boxSizeReqUpdater t2 <|> _boxSizeReqUpdater t1,
    _boxMergeRequired = _boxMergeRequired t2 <|> _boxMergeRequired t1,
    _boxAlignH = _boxAlignH t2 <|> _boxAlignH t1,
    _boxAlignV = _boxAlignV t2 <|> _boxAlignV t1,
    _boxOnFocusReq = _boxOnFocusReq t1 <> _boxOnFocusReq t2,
    _boxOnBlurReq = _boxOnBlurReq t1 <> _boxOnBlurReq t2,
    _boxOnEnterReq = _boxOnEnterReq t1 <> _boxOnEnterReq t2,
    _boxOnLeaveReq = _boxOnLeaveReq t1 <> _boxOnLeaveReq t2,
    _boxOnClickReq = _boxOnClickReq t1 <> _boxOnClickReq t2,
    _boxOnClickEmptyReq = _boxOnClickEmptyReq t1 <> _boxOnClickEmptyReq t2,
    _boxOnBtnPressedReq = _boxOnBtnPressedReq t1 <> _boxOnBtnPressedReq t2,
    _boxOnBtnReleasedReq = _boxOnBtnReleasedReq t1 <> _boxOnBtnReleasedReq t2
  }

instance Monoid (BoxCfg s e) where
  mempty = def

instance CmbIgnoreEmptyArea (BoxCfg s e) where
  ignoreEmptyArea_ ignore = def {
    _boxIgnoreEmptyArea = Just ignore
  }

instance CmbSizeReqUpdater (BoxCfg s e) where
  sizeReqUpdater updater = def {
    _boxSizeReqUpdater = Just updater
  }

instance CmbMergeRequired (BoxCfg s e) s where
  mergeRequired fn = def {
    _boxMergeRequired = Just fn
  }

instance CmbAlignLeft (BoxCfg s e) where
  alignLeft_ False = def
  alignLeft_ True = def {
    _boxAlignH = Just ALeft
  }

instance CmbAlignCenter (BoxCfg s e) where
  alignCenter_ False = def
  alignCenter_ True = def {
    _boxAlignH = Just ACenter
  }

instance CmbAlignRight (BoxCfg s e) where
  alignRight_ False = def
  alignRight_ True = def {
    _boxAlignH = Just ARight
  }

instance CmbAlignTop (BoxCfg s e) where
  alignTop_ False = def
  alignTop_ True = def {
    _boxAlignV = Just ATop
  }

instance CmbAlignMiddle (BoxCfg s e) where
  alignMiddle_ False = def
  alignMiddle_ True = def {
    _boxAlignV = Just AMiddle
  }

instance CmbAlignBottom (BoxCfg s e) where
  alignBottom_ False = def
  alignBottom_ True = def {
    _boxAlignV = Just ABottom
  }

instance WidgetEvent e => CmbOnFocus (BoxCfg s e) e Path where
  onFocus handler = def {
    _boxOnFocusReq = [RaiseEvent . handler]
  }

instance CmbOnFocusReq (BoxCfg s e) s e Path where
  onFocusReq req = def {
    _boxOnFocusReq = [req]
  }

instance WidgetEvent e => CmbOnBlur (BoxCfg s e) e Path where
  onBlur handler = def {
    _boxOnBlurReq = [RaiseEvent . handler]
  }

instance CmbOnBlurReq (BoxCfg s e) s e Path where
  onBlurReq req = def {
    _boxOnBlurReq = [req]
  }

instance WidgetEvent e => CmbOnBtnPressed (BoxCfg s e) e where
  onBtnPressed handler = def {
    _boxOnBtnPressedReq = [(RaiseEvent .) . handler]
  }

instance CmbOnBtnPressedReq (BoxCfg s e) s e where
  onBtnPressedReq req = def {
    _boxOnBtnPressedReq = [req]
  }

instance WidgetEvent e => CmbOnBtnReleased (BoxCfg s e) e where
  onBtnReleased handler = def {
    _boxOnBtnReleasedReq = [(RaiseEvent .) . handler]
  }

instance CmbOnBtnReleasedReq (BoxCfg s e) s e where
  onBtnReleasedReq req = def {
    _boxOnBtnReleasedReq = [req]
  }

instance WidgetEvent e => CmbOnClick (BoxCfg s e) e where
  onClick handler = def {
    _boxOnClickReq = [RaiseEvent handler]
  }

instance CmbOnClickReq (BoxCfg s e) s e where
  onClickReq req = def {
    _boxOnClickReq = [req]
  }

instance WidgetEvent e => CmbOnClickEmpty (BoxCfg s e) e where
  onClickEmpty handler = def {
    _boxOnClickEmptyReq = [RaiseEvent handler]
  }

instance CmbOnClickEmptyReq (BoxCfg s e) s e where
  onClickEmptyReq req = def {
    _boxOnClickEmptyReq = [req]
  }

instance WidgetEvent e => CmbOnEnter (BoxCfg s e) e where
  onEnter handler = def {
    _boxOnEnterReq = [RaiseEvent handler]
  }

instance CmbOnEnterReq (BoxCfg s e) s e where
  onEnterReq req = def {
    _boxOnEnterReq = [req]
  }

instance WidgetEvent e => CmbOnLeave (BoxCfg s e) e where
  onLeave handler = def {
    _boxOnLeaveReq = [RaiseEvent handler]
  }

instance CmbOnLeaveReq (BoxCfg s e) s e where
  onLeaveReq req = def {
    _boxOnLeaveReq = [req]
  }

-- | Assigns all the available space to its contained child.
expandContent :: BoxCfg s e
expandContent = def {
  _boxExpandContent = Just True
}

newtype BoxState s = BoxState {
  _bxsModel :: Maybe s
}

-- | Creates a box widget with a single node as child.
box :: (WidgetModel s, WidgetEvent e) => WidgetNode s e -> WidgetNode s e
box managed = box_ def managed

-- | Creates a box widget with a single node as child. Accepts config.
box_
  :: (WidgetModel s, WidgetEvent e)
  => [BoxCfg s e]
  -> WidgetNode s e
  -> WidgetNode s e
box_ configs managed = makeNode (makeBox config state) managed where
  config = mconcat configs
  state = BoxState Nothing

makeNode :: Widget s e -> WidgetNode s e -> WidgetNode s e
makeNode widget managedWidget = defaultWidgetNode "box" widget
  & L.info . L.focusable .~ False
  & L.children .~ Seq.singleton managedWidget

makeBox
  :: (WidgetModel s, WidgetEvent e)
  => BoxCfg s e
  -> BoxState s
  -> Widget s e
makeBox config state = widget where
  widget = createContainer state def {
    containerIgnoreEmptyArea = ignoreEmptyArea && emptyHandlersCount == 0,
    containerGetCurrentStyle = getCurrentStyle,
    containerInit = init,
    containerMergeChildrenReq = mergeRequired,
    containerMerge = merge,
    containerHandleEvent = handleEvent,
    containerGetSizeReq = getSizeReq,
    containerResize = resize
  }

  ignoreEmptyArea = Just True == _boxIgnoreEmptyArea config
  emptyHandlersCount = length (_boxOnClickEmptyReq config)

  init wenv node = resultNode newNode where
    newState = BoxState (Just $ wenv ^. L.model)
    newNode = node
      & L.widget .~ makeBox config newState

  mergeRequired wenv node oldNode oldState = required where
    newModel = wenv ^. L.model
    required = case (_boxMergeRequired config, _bxsModel oldState) of
      (Just mergeReqFn, Just oldModel) -> mergeReqFn oldModel newModel
      _ -> True

  merge wenv node oldNode oldState = resultNode newNode where
    newState = BoxState (Just $ wenv ^. L.model)
    newNode = node
      & L.widget .~ makeBox config newState

  getCurrentStyle = currentStyle_ currentStyleConfig where
    currentStyleConfig = def
      & L.isActive .~ isNodeTreeActive

  handleEvent wenv node target evt = case evt of
    Focus prev -> handleFocusChange node prev (_boxOnFocusReq config)
    Blur next -> handleFocusChange node next (_boxOnBlurReq config)

    Enter point
      | not (null reqs) && inChildVp point -> result where
        reqs = _boxOnEnterReq config
        result = Just (resultReqs node reqs)

    Leave point
      | not (null reqs) -> result where
        reqs = _boxOnLeaveReq config
        result = Just (resultReqs node reqs)

    Click point btn _
      | not (null reqs) && inChildVp point -> result where
        reqs = _boxOnClickReq config
        result = Just (resultReqs node reqs)

    Click point btn _
      | not (null reqs) && not (inChildVp point) -> result where
        reqs = _boxOnClickEmptyReq config
        result = Just (resultReqs node reqs)

    ButtonAction point btn BtnPressed clicks
      | not (null reqs) && inChildVp point -> result where
        reqs = _boxOnBtnPressedReq config <*> pure btn <*> pure clicks
        result = Just (resultReqs node reqs)

    ButtonAction point btn BtnReleased clicks
      | clicks == 1 && not (null reqs) && inChildVp point -> result where
        reqs = _boxOnBtnReleasedReq config <*> pure btn <*> pure clicks
        result = Just (resultReqs node reqs)

    ButtonAction point btn BtnReleased clicks
      | clicks > 1 && not (null reqs) && inChildVp point -> result where
        reqsA = _boxOnClickReq config
        reqsB = _boxOnBtnReleasedReq config <*> pure btn <*> pure clicks
        reqs = reqsA <> reqsB
        result = Just (resultReqs node reqs)

    ButtonAction point btn BtnReleased clicks
      | clicks > 1 && not (null reqs) && not (inChildVp point) -> result where
        reqs = _boxOnClickEmptyReq config
        result = Just (resultReqs node reqs)

    _ -> Nothing
    where
      child = Seq.index (node ^. L.children) 0
      inChildVp point  = pointInRect point (child ^. L.info . L.viewport)

  getSizeReq :: ContainerGetSizeReqHandler s e
  getSizeReq wenv node children = newSizeReq where
    updateSizeReq = fromMaybe id (_boxSizeReqUpdater config)
    child = Seq.index children 0
    newReqW = child ^. L.info . L.sizeReqW
    newReqH = child ^. L.info . L.sizeReqH
    newSizeReq = updateSizeReq (newReqW, newReqH)

  resize wenv node viewport children = resized where
    style = getCurrentStyle wenv node
    child = Seq.index children 0
    contentArea = fromMaybe def (removeOuterBounds style viewport)
    Rect cx cy cw ch = contentArea

    contentW = snd $ assignStackAreas True contentArea children
    contentH = snd $ assignStackAreas False contentArea children

    raChild = Rect cx cy (min cw contentW) (min ch contentH)
    ah = fromMaybe ACenter (_boxAlignH config)
    av = fromMaybe AMiddle (_boxAlignV config)
    raAligned = alignInRect contentArea raChild ah av

    expand = fromMaybe False (_boxExpandContent config)
    resized
      | expand = (resultNode node, Seq.singleton contentArea)
      | otherwise = (resultNode node, Seq.singleton raAligned)
