import 'package:flutter/material.dart';

import '../models/block_template.dart';
import '../models/block_type.dart';

const Color eventColor = Color(0xfff6c344);
const Color motionColor = Color(0xff4c97ff);
const Color looksColor = Color(0xff9966ff);
const Color soundColor = Color(0xffff5ca8);
const Color controlColor = Color(0xffffab19);
const Color sensingColor = Color(0xff5cb1d6);
const Color operatorsColor = Color(0xff59c059);
const Color variablesColor = Color(0xffff8c1a);
const Color listsColor = Color(0xffff661a);

const List<String> defaultVariables = ['score', 'lives', 'speed'];

const Map<BlockType, String> blockCategoryNames = {
  BlockType.event: 'Events',
  BlockType.motion: 'Motion',
  BlockType.looks: 'Looks',
  BlockType.sound: 'Sound',
  BlockType.control: 'Control',
  BlockType.sensing: 'Sensing',
  BlockType.operators: 'Operators',
  BlockType.variables: 'Variables',
  BlockType.lists: 'Lists',
};

const Map<BlockType, Color> blockCategoryColors = {
  BlockType.event: eventColor,
  BlockType.motion: motionColor,
  BlockType.looks: looksColor,
  BlockType.sound: soundColor,
  BlockType.control: controlColor,
  BlockType.sensing: sensingColor,
  BlockType.operators: operatorsColor,
  BlockType.variables: variablesColor,
  BlockType.lists: listsColor,
};

const List<BlockTemplate> blockTemplates = [
  BlockTemplate(
    type: BlockType.event,
    label: 'When Start Clicked',
    color: eventColor,
    shape: BlockShape.hat,
  ),
  BlockTemplate(
    type: BlockType.motion,
    label: 'Move {steps} Steps',
    color: motionColor,
    inputs: [
      BlockInput(key: 'steps', type: BlockInputType.number, defaultValue: '10'),
    ],
  ),
  BlockTemplate(
    type: BlockType.motion,
    label: 'Turn {degrees}\u00b0',
    color: motionColor,
    inputs: [
      BlockInput(
        key: 'degrees',
        type: BlockInputType.number,
        defaultValue: '15',
      ),
    ],
  ),
  BlockTemplate(
    type: BlockType.motion,
    label: 'Go To X: {x} Y: {y}',
    color: motionColor,
    inputs: [
      BlockInput(key: 'x', type: BlockInputType.number, defaultValue: '0'),
      BlockInput(key: 'y', type: BlockInputType.number, defaultValue: '0'),
    ],
  ),
  BlockTemplate(
    type: BlockType.looks,
    label: 'Say {message}',
    color: looksColor,
    inputs: [
      BlockInput(
        key: 'message',
        type: BlockInputType.text,
        defaultValue: 'Hello!',
      ),
    ],
  ),
  BlockTemplate(
    type: BlockType.looks,
    label: 'Think {message}',
    color: looksColor,
    inputs: [
      BlockInput(
        key: 'message',
        type: BlockInputType.text,
        defaultValue: 'Hmm...',
      ),
    ],
  ),
  BlockTemplate(
    type: BlockType.control,
    label: 'Wait {seconds} Second',
    color: controlColor,
    inputs: [
      BlockInput(
        key: 'seconds',
        type: BlockInputType.number,
        defaultValue: '1',
      ),
    ],
  ),
  BlockTemplate(
    type: BlockType.control,
    label: 'Repeat {times} Times',
    color: controlColor,
    shape: BlockShape.cBlock,
    isContainer: true,
    inputs: [
      BlockInput(key: 'times', type: BlockInputType.number, defaultValue: '5'),
    ],
  ),
  BlockTemplate(
    type: BlockType.sensing,
    label: 'Key {key} Pressed?',
    color: sensingColor,
    shape: BlockShape.boolean,
    inputs: [
      BlockInput(
        key: 'key',
        type: BlockInputType.dropdown,
        defaultValue: 'space',
        options: ['space', 'up', 'down', 'left', 'right'],
      ),
    ],
  ),
  BlockTemplate(
    type: BlockType.operators,
    label: '{a} + {b}',
    color: operatorsColor,
    shape: BlockShape.reporter,
    inputs: [
      BlockInput(key: 'a', type: BlockInputType.number, defaultValue: '1'),
      BlockInput(key: 'b', type: BlockInputType.number, defaultValue: '1'),
    ],
  ),
  BlockTemplate(
    type: BlockType.operators,
    label: '{a} > {b}',
    color: operatorsColor,
    shape: BlockShape.boolean,
    inputs: [
      BlockInput(key: 'a', type: BlockInputType.number, defaultValue: '1'),
      BlockInput(key: 'b', type: BlockInputType.number, defaultValue: '0'),
    ],
  ),
  BlockTemplate(
    type: BlockType.variables,
    label: 'Set {variable} To {value}',
    color: variablesColor,
    inputs: [
      BlockInput(
        key: 'variable',
        type: BlockInputType.variable,
        defaultValue: 'score',
        options: defaultVariables,
      ),
      BlockInput(key: 'value', type: BlockInputType.number, defaultValue: '0'),
    ],
  ),
  BlockTemplate(
    type: BlockType.variables,
    label: 'Change {variable} By {value}',
    color: variablesColor,
    inputs: [
      BlockInput(
        key: 'variable',
        type: BlockInputType.variable,
        defaultValue: 'score',
        options: defaultVariables,
      ),
      BlockInput(key: 'value', type: BlockInputType.number, defaultValue: '1'),
    ],
  ),
  BlockTemplate(
    type: BlockType.variables,
    label: '{variable}',
    color: variablesColor,
    shape: BlockShape.reporter,
    inputs: [
      BlockInput(
        key: 'variable',
        type: BlockInputType.variable,
        defaultValue: 'score',
        options: defaultVariables,
      ),
    ],
  ),
];
