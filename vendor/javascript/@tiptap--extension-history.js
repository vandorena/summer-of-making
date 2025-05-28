// @tiptap/extension-history@2.12.0 downloaded from https://ga.jspm.io/npm:@tiptap/extension-history@2.12.0/dist/index.js

import{Extension as o}from"@tiptap/core";import{history as t,redo as d,undo as r}from"@tiptap/pm/history";const e=o.create({name:"history",addOptions(){return{depth:100,newGroupDelay:500}},addCommands(){return{undo:()=>({state:o,dispatch:t})=>r(o,t),redo:()=>({state:o,dispatch:t})=>d(o,t)}},addProseMirrorPlugins(){return[t(this.options)]},addKeyboardShortcuts(){return{"Mod-z":()=>this.editor.commands.undo(),"Shift-Mod-z":()=>this.editor.commands.redo(),"Mod-y":()=>this.editor.commands.redo(),"Mod-я":()=>this.editor.commands.undo(),"Shift-Mod-я":()=>this.editor.commands.redo()}}});export{e as History,e as default};

