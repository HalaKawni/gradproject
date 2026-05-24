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
const List<String> defaultKeys = [
  'up',
  'down',
  'left',
  'right',
  'space',
  'w',
  'a',
  's',
  'd',
];
const List<String> defaultObjects = ['banana', 'polar'];
const List<String> defaultCounters = ['score', 'lives'];
const List<String> defaultTimers = ['timer'];
const List<String> defaultSounds = ['collect'];
const List<String> defaultBackgrounds = ['forest', 'sky'];

const Map<BlockType, String> blockCategoryNames = {
  BlockType.event: 'Events',
  BlockType.motion: 'Motion',
  BlockType.looks: 'Looks',
  BlockType.sound: 'Sound',
  BlockType.control: 'Control',
  BlockType.sensing: 'Sensing',
  BlockType.operators: 'Operators',
  BlockType.variables: 'Variables',
  BlockType.lists: 'Game',
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

final List<BlockTemplate> blockTemplates = [
  BlockTemplate(
    id: 'event_when_start',
    type: BlockType.event,
    label: 'when game starts',
    color: eventColor,
    shape: BlockShape.hat,
  ),
  BlockTemplate(
    id: 'event_when_key',
    type: BlockType.event,
    label: 'when key {key} pressed',
    color: eventColor,
    shape: BlockShape.hat,
    enabled: false,
    inputs: [
      BlockInput(
        key: 'key',
        type: BlockInputType.dropdown,
        defaultValue: 'right',
        options: defaultKeys,
      ),
    ],
  ),
  BlockTemplate(
    id: 'event_when_sprite_clicked',
    type: BlockType.event,
    label: 'when this sprite clicked',
    color: eventColor,
    shape: BlockShape.hat,
    enabled: false,
  ),
  BlockTemplate(
    id: 'event_when_touching',
    type: BlockType.event,
    label: 'when touching {object}',
    color: eventColor,
    shape: BlockShape.hat,
    inputs: [
      BlockInput(
        key: 'object',
        type: BlockInputType.dropdown,
        defaultValue: 'banana',
        options: defaultObjects,
      ),
    ],
  ),
  BlockTemplate(
    id: 'event_forever_update',
    type: BlockType.event,
    label: 'forever update',
    color: eventColor,
    shape: BlockShape.hat,
    enabled: false,
  ),
  BlockTemplate(
    id: 'event_when_timer_ends',
    type: BlockType.event,
    label: 'when timer ends',
    color: eventColor,
    shape: BlockShape.hat,
    enabled: false,
  ),
  BlockTemplate(
    id: 'motion_step',
    type: BlockType.motion,
    label: 'step {steps}',
    color: motionColor,
    inputs: [
      BlockInput(key: 'steps', type: BlockInputType.number, defaultValue: '1'),
    ],
  ),
  BlockTemplate(
    id: 'motion_turn_left',
    type: BlockType.motion,
    label: 'turn left',
    color: motionColor,
  ),
  BlockTemplate(
    id: 'motion_turn_right',
    type: BlockType.motion,
    label: 'turn right',
    color: motionColor,
  ),
  BlockTemplate(
    id: 'motion_turn_degrees',
    type: BlockType.motion,
    label: 'turn {degrees} deg',
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
    id: 'motion_set_rotation',
    type: BlockType.motion,
    label: 'set rotation {degrees}',
    color: motionColor,
    inputs: [
      BlockInput(
        key: 'degrees',
        type: BlockInputType.number,
        defaultValue: '0',
      ),
    ],
  ),
  for (final direction in ['right', 'left', 'up', 'down'])
    BlockTemplate(
      id: 'motion_move_$direction',
      type: BlockType.motion,
      label: 'move $direction',
      color: motionColor,
    ),
  BlockTemplate(
    id: 'motion_jump_up',
    type: BlockType.motion,
    label: 'jump up',
    color: motionColor,
  ),
  BlockTemplate(
    id: 'motion_jump_right',
    type: BlockType.motion,
    label: 'jump right',
    color: motionColor,
  ),
  BlockTemplate(
    id: 'motion_jump_left',
    type: BlockType.motion,
    label: 'jump left',
    color: motionColor,
  ),
  BlockTemplate(
    id: 'motion_go_to',
    type: BlockType.motion,
    label: 'go to x {x} y {y}',
    color: motionColor,
    inputs: [
      BlockInput(key: 'x', type: BlockInputType.number, defaultValue: '72'),
      BlockInput(key: 'y', type: BlockInputType.number, defaultValue: '284'),
    ],
  ),
  BlockTemplate(
    id: 'motion_change_x',
    type: BlockType.motion,
    label: 'change x by {value}',
    color: motionColor,
    inputs: [
      BlockInput(key: 'value', type: BlockInputType.number, defaultValue: '40'),
    ],
  ),
  BlockTemplate(
    id: 'motion_change_y',
    type: BlockType.motion,
    label: 'change y by {value}',
    color: motionColor,
    inputs: [
      BlockInput(key: 'value', type: BlockInputType.number, defaultValue: '40'),
    ],
  ),
  BlockTemplate(
    id: 'motion_set_x',
    type: BlockType.motion,
    label: 'set x to {x}',
    color: motionColor,
    inputs: [
      BlockInput(key: 'x', type: BlockInputType.number, defaultValue: '72'),
    ],
  ),
  BlockTemplate(
    id: 'motion_set_y',
    type: BlockType.motion,
    label: 'set y to {y}',
    color: motionColor,
    inputs: [
      BlockInput(key: 'y', type: BlockInputType.number, defaultValue: '284'),
    ],
  ),
  BlockTemplate(
    id: 'motion_x_position',
    type: BlockType.motion,
    label: 'x position',
    color: motionColor,
    shape: BlockShape.reporter,
    outputType: BlockOutputType.number,
  ),
  BlockTemplate(
    id: 'motion_y_position',
    type: BlockType.motion,
    label: 'y position',
    color: motionColor,
    shape: BlockShape.reporter,
    outputType: BlockOutputType.number,
  ),
  BlockTemplate(
    id: 'motion_rotation',
    type: BlockType.motion,
    label: 'rotation',
    color: motionColor,
    shape: BlockShape.reporter,
    outputType: BlockOutputType.number,
  ),
  BlockTemplate(
    id: 'motion_distance_to',
    type: BlockType.motion,
    label: 'distance to {object}',
    color: motionColor,
    shape: BlockShape.reporter,
    outputType: BlockOutputType.number,
    inputs: [
      BlockInput(
        key: 'object',
        type: BlockInputType.dropdown,
        defaultValue: 'banana',
        options: defaultObjects,
      ),
    ],
  ),
  BlockTemplate(
    id: 'looks_show',
    type: BlockType.looks,
    label: 'show',
    color: looksColor,
  ),
  BlockTemplate(
    id: 'looks_hide',
    type: BlockType.looks,
    label: 'hide',
    color: looksColor,
  ),
  BlockTemplate(
    id: 'looks_say',
    type: BlockType.looks,
    label: 'say {message}',
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
    id: 'looks_say_for',
    type: BlockType.looks,
    label: 'say {message} for {seconds}',
    color: looksColor,
    inputs: [
      BlockInput(
        key: 'message',
        type: BlockInputType.text,
        defaultValue: 'Hello!',
      ),
      BlockInput(
        key: 'seconds',
        type: BlockInputType.number,
        defaultValue: '2',
      ),
    ],
  ),
  BlockTemplate(
    id: 'looks_set_scale',
    type: BlockType.looks,
    label: 'set scale to {value}',
    color: looksColor,
    inputs: [
      BlockInput(key: 'value', type: BlockInputType.number, defaultValue: '1'),
    ],
  ),
  BlockTemplate(
    id: 'looks_change_scale',
    type: BlockType.looks,
    label: 'change scale by {value}',
    color: looksColor,
    inputs: [
      BlockInput(
        key: 'value',
        type: BlockInputType.number,
        defaultValue: '0.2',
      ),
    ],
  ),
  BlockTemplate(
    id: 'looks_scale',
    type: BlockType.looks,
    label: 'scale',
    color: looksColor,
    shape: BlockShape.reporter,
    outputType: BlockOutputType.number,
  ),
  BlockTemplate(
    id: 'looks_destroy',
    type: BlockType.looks,
    label: 'destroy',
    color: looksColor,
  ),
  BlockTemplate(
    id: 'control_wait',
    type: BlockType.control,
    label: 'wait {seconds}',
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
    id: 'control_repeat',
    type: BlockType.control,
    label: 'repeat {times}',
    color: controlColor,
    shape: BlockShape.cBlock,
    isContainer: true,
    inputs: [
      BlockInput(key: 'times', type: BlockInputType.number, defaultValue: '3'),
    ],
  ),
  BlockTemplate(
    id: 'control_forever',
    type: BlockType.control,
    label: 'forever',
    color: controlColor,
    shape: BlockShape.cBlock,
    isContainer: true,
  ),
  BlockTemplate(
    id: 'control_if',
    type: BlockType.control,
    label: 'if {condition}',
    color: controlColor,
    shape: BlockShape.cBlock,
    isContainer: true,
    inputs: [
      BlockInput(
        key: 'condition',
        type: BlockInputType.boolean,
        defaultValue: 'touching banana',
      ),
    ],
  ),
  BlockTemplate(
    id: 'control_repeat_until',
    type: BlockType.control,
    label: 'repeat until {condition}',
    color: controlColor,
    shape: BlockShape.cBlock,
    isContainer: true,
    inputs: [
      BlockInput(
        key: 'condition',
        type: BlockInputType.boolean,
        defaultValue: 'touching banana',
      ),
    ],
  ),
  BlockTemplate(
    id: 'control_stop_script',
    type: BlockType.control,
    label: 'stop this script',
    color: controlColor,
    shape: BlockShape.cap,
  ),
  BlockTemplate(
    id: 'control_stop_game',
    type: BlockType.control,
    label: 'stop game',
    color: controlColor,
    shape: BlockShape.cap,
  ),
  BlockTemplate(
    id: 'sensing_touching',
    type: BlockType.sensing,
    label: 'touching {object}',
    color: sensingColor,
    shape: BlockShape.boolean,
    outputType: BlockOutputType.boolean,
    inputs: [
      BlockInput(
        key: 'object',
        type: BlockInputType.dropdown,
        defaultValue: 'banana',
        options: defaultObjects,
      ),
    ],
  ),
  BlockTemplate(
    id: 'sensing_near',
    type: BlockType.sensing,
    label: 'near {object}',
    color: sensingColor,
    shape: BlockShape.boolean,
    outputType: BlockOutputType.boolean,
    inputs: [
      BlockInput(
        key: 'object',
        type: BlockInputType.dropdown,
        defaultValue: 'banana',
        options: defaultObjects,
      ),
    ],
  ),
  BlockTemplate(
    id: 'sensing_visible',
    type: BlockType.sensing,
    label: '{object} is visible',
    color: sensingColor,
    shape: BlockShape.boolean,
    outputType: BlockOutputType.boolean,
    inputs: [
      BlockInput(
        key: 'object',
        type: BlockInputType.dropdown,
        defaultValue: 'banana',
        options: defaultObjects,
      ),
    ],
  ),
  BlockTemplate(
    id: 'operator_equals',
    type: BlockType.operators,
    label: '{a} = {b}',
    color: operatorsColor,
    shape: BlockShape.boolean,
    outputType: BlockOutputType.boolean,
    inputs: [
      BlockInput(key: 'a', type: BlockInputType.text, defaultValue: 'score'),
      BlockInput(key: 'b', type: BlockInputType.text, defaultValue: '1'),
    ],
  ),
  for (final op in ['<', '<=', '>', '>='])
    BlockTemplate(
      id: 'operator_${op.replaceAll('=', 'eq').replaceAll('<', 'lt').replaceAll('>', 'gt')}',
      type: BlockType.operators,
      label: '{a} $op {b}',
      color: operatorsColor,
      shape: BlockShape.boolean,
      outputType: BlockOutputType.boolean,
      inputs: [
        BlockInput(key: 'a', type: BlockInputType.text, defaultValue: 'score'),
        BlockInput(key: 'b', type: BlockInputType.text, defaultValue: '1'),
      ],
    ),
  BlockTemplate(
    id: 'operator_not',
    type: BlockType.operators,
    label: 'not {condition}',
    color: operatorsColor,
    shape: BlockShape.boolean,
    outputType: BlockOutputType.boolean,
    inputs: [
      BlockInput(
        key: 'condition',
        type: BlockInputType.boolean,
        defaultValue: 'touching banana',
      ),
    ],
  ),
  BlockTemplate(
    id: 'operator_true',
    type: BlockType.operators,
    label: 'true',
    color: operatorsColor,
    shape: BlockShape.boolean,
    outputType: BlockOutputType.boolean,
  ),
  BlockTemplate(
    id: 'operator_false',
    type: BlockType.operators,
    label: 'false',
    color: operatorsColor,
    shape: BlockShape.boolean,
    outputType: BlockOutputType.boolean,
  ),
  BlockTemplate(
    id: 'operator_random',
    type: BlockType.operators,
    label: 'random from {min} to {max}',
    color: operatorsColor,
    shape: BlockShape.reporter,
    outputType: BlockOutputType.number,
    inputs: [
      BlockInput(key: 'min', type: BlockInputType.number, defaultValue: '0'),
      BlockInput(key: 'max', type: BlockInputType.number, defaultValue: '300'),
    ],
  ),
  BlockTemplate(
    id: 'variables_set',
    type: BlockType.variables,
    label: 'set {variable} to {value}',
    color: variablesColor,
    inputs: [
      BlockInput(
        key: 'variable',
        type: BlockInputType.variable,
        defaultValue: 'score',
        options: defaultVariables,
      ),
      BlockInput(key: 'value', type: BlockInputType.text, defaultValue: '0'),
    ],
  ),
  BlockTemplate(
    id: 'variables_change',
    type: BlockType.variables,
    label: 'change {variable} by {value}',
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
    id: 'variables_reporter',
    type: BlockType.variables,
    label: '{variable}',
    color: variablesColor,
    shape: BlockShape.reporter,
    outputType: BlockOutputType.number,
    inputs: [
      BlockInput(
        key: 'variable',
        type: BlockInputType.variable,
        defaultValue: 'score',
        options: defaultVariables,
      ),
    ],
  ),
  BlockTemplate(
    id: 'game_set_counter',
    type: BlockType.lists,
    label: 'set counter {counter} to {value}',
    color: listsColor,
    inputs: [
      BlockInput(
        key: 'counter',
        type: BlockInputType.dropdown,
        defaultValue: 'score',
        options: defaultCounters,
      ),
      BlockInput(key: 'value', type: BlockInputType.number, defaultValue: '0'),
    ],
  ),
  BlockTemplate(
    id: 'game_change_counter',
    type: BlockType.lists,
    label: 'change counter {counter} by {value}',
    color: listsColor,
    inputs: [
      BlockInput(
        key: 'counter',
        type: BlockInputType.dropdown,
        defaultValue: 'score',
        options: defaultCounters,
      ),
      BlockInput(key: 'value', type: BlockInputType.number, defaultValue: '1'),
    ],
  ),
  BlockTemplate(
    id: 'game_reset',
    type: BlockType.lists,
    label: 'reset game',
    color: listsColor,
  ),
  BlockTemplate(
    id: 'game_pause',
    type: BlockType.lists,
    label: 'pause game',
    color: listsColor,
    enabled: false,
  ),
  BlockTemplate(
    id: 'game_unpause',
    type: BlockType.lists,
    label: 'unpause game',
    color: listsColor,
    enabled: false,
  ),
  BlockTemplate(
    id: 'sound_play',
    type: BlockType.sound,
    label: 'play sound {sound}',
    color: soundColor,
    enabled: false,
    inputs: [
      BlockInput(
        key: 'sound',
        type: BlockInputType.dropdown,
        defaultValue: 'collect',
        options: defaultSounds,
      ),
    ],
  ),
  BlockTemplate(
    id: 'game_time',
    type: BlockType.lists,
    label: 'game time',
    color: listsColor,
    shape: BlockShape.reporter,
    outputType: BlockOutputType.number,
  ),
];
