/**
* The MIT License (MIT)
*
* Copyright (c) 2016-present ElemeFE
*
* https://opensource.org/licenses/mit-license.php
*/

let hiddenTextarea;
const hiddenElements = {};

const HIDDEN_STYLE = `
  height:0 !important;
  visibility:hidden !important;
  overflow:hidden !important;
  position:absolute !important;
  z-index:-1000 !important;
  top:0 !important;
  right:0 !important
`;

const CONTEXT_STYLE = [
  'letter-spacing',
  'line-height',
  'padding-top',
  'padding-bottom',
  'font-family',
  'font-weight',
  'font-size',
  'text-rendering',
  'text-transform',
  'width',
  'text-indent',
  'padding-left',
  'padding-right',
  'border-width',
  'box-sizing',
];

function calculateNodeStyling(targetElement) {
  const style = window.getComputedStyle(targetElement);

  const boxSizing = style.getPropertyValue('box-sizing');

  const paddingSize = (
    parseFloat(style.getPropertyValue('padding-bottom')) +
    parseFloat(style.getPropertyValue('padding-top'))
  );

  const borderSize = (
    parseFloat(style.getPropertyValue('border-bottom-width')) +
    parseFloat(style.getPropertyValue('border-top-width'))
  );

  const contextStyle = CONTEXT_STYLE
    .map(name => `${name}:${style.getPropertyValue(name)}`)
    .join(';');

  return { contextStyle, paddingSize, borderSize, boxSizing };
}

export function calcTextareaHeight(targetElement, minRows = 1, maxRows = null) {
  if (!hiddenTextarea) {
    hiddenTextarea = document.createElement('textarea');
    document.body.appendChild(hiddenTextarea);
  }

  const {
    paddingSize,
    borderSize,
    boxSizing,
    contextStyle,
  } = calculateNodeStyling(targetElement);

  hiddenTextarea.setAttribute('style', `${contextStyle};${HIDDEN_STYLE}`);
  hiddenTextarea.value = targetElement.value || targetElement.placeholder || '';

  let height = hiddenTextarea.scrollHeight;
  const result = {};

  if (boxSizing === 'border-box') {
    height += borderSize;
  } else if (boxSizing === 'content-box') {
    height -= paddingSize;
  }

  hiddenTextarea.value = '';
  const singleRowHeight = hiddenTextarea.scrollHeight - paddingSize;

  if (minRows !== null) {
    let minHeight = singleRowHeight * minRows;
    if (boxSizing === 'border-box') {
      minHeight = minHeight + paddingSize + borderSize;
    }
    height = Math.max(minHeight, height);
    result.minHeight = `${minHeight}px`;
  }
  if (maxRows !== null) {
    let maxHeight = singleRowHeight * maxRows;
    if (boxSizing === 'border-box') {
      maxHeight = maxHeight + paddingSize + borderSize;
    }
    height = Math.min(maxHeight, height);
  }
  result.height = `${height}px`;
  if (hiddenTextarea.parentNode) hiddenTextarea.parentNode.removeChild(hiddenTextarea);
  hiddenTextarea = null;
  return result;
}

export function calcElementHeight(targetElement) {
  const tag = targetElement.tagname;
  if (!hiddenElements[tag]) {
    hiddenElements[tag] = document.createElement(tag);
    document.body.appendChild(hiddenElements[tag]);
  }
  const hiddenElement = hiddenElements[tag];

  const {
    paddingSize,
    borderSize,
    boxSizing,
    contextStyle,
  } = calculateNodeStyling(targetElement);

  hiddenElement.setAttribute('style', `${contextStyle};${HIDDEN_STYLE}`);
  hiddenElement.innerHTML = targetElement.innerHTML;

  let height = hiddenElement.scrollHeight;
  const result = {};

  if (boxSizing === 'border-box') {
    height += borderSize;
  } else if (boxSizing === 'content-box') {
    height -= paddingSize;
  }

  result.height = `${height}px`;
  if (hiddenElement.parentNode) hiddenElement.parentNode.removeChild(hiddenElement);
  hiddenElements[tag] = null;
  return result;
}
