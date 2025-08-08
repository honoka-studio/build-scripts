//noinspection JSCheckFunctionSignatures

import fs from 'fs'
import path from 'path'

function seperator() {
  console.log('-----------------------------------')
}

if(process.argv.length < 3) {
  console.log('Must specify a root project path!')
  process.exit(1)
}

const rootPath = process.argv[2]
if(!fs.existsSync(path.join(rootPath, 'package.json'))) {
  console.log(`The directory "${rootPath}" is not a root project.`)
  process.exit(1)
}

let paths = [path.join(rootPath, 'package.json')]
let jsons = []

function findPackageJson(dir) {
  fs.readdirSync(dir, { withFileTypes: true }).forEach(it => {
    if(!it.isDirectory() || it.name === 'node_modules') return
    let jsonPath = path.join(dir, it.name, 'package.json')
    if(fs.existsSync(jsonPath)) {
      paths.push(jsonPath)
    }
    findPackageJson(path.join(dir, it.name))
  })
}

findPackageJson(rootPath)

seperator()

let projectsPassed = true
let dependenciesPassed = true

console.log('Versions:\n')
for(let p of paths) {
  let json = JSON.parse(fs.readFileSync(p))
  jsons.push(json)
  console.log(`${json.name}=${json.version}`)
  if(json.version.includes('dev')) {
    projectsPassed = false
    break
  }
}

seperator()

if(projectsPassed) {
  console.log('Dependencies:\n')

  function checkDependencies(dependencies) {
    if(!dependencies || !dependenciesPassed) return
    for(let key in dependencies) {
      console.log(`${key}=${dependencies[key]}`)
      if(dependencies[key].includes('dev')) {
        dependenciesPassed = false
        return
      }
    }
  }

  for(let json of jsons) {
    if(!dependenciesPassed) break
    checkDependencies(json.dependencies)
    //noinspection JSUnresolvedReference
    checkDependencies(json.devDependencies)
  }

  seperator()
}

console.log('Results:\n')
console.log(`results.projectsPassed=${projectsPassed}`)
console.log(`results.dependenciesPassed=${dependenciesPassed}`)

seperator()
