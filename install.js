#!/usr/bin/env node
const fsPromise = require('fsPromise');

function symlink(target, path) {
  return fsPromise.symlink(`${target}`, `${path}`,'file')
}

function rename(existingName, newName){
  fsPromise.rename();
}


console.log("Install dotfiles")
