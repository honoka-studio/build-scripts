//noinspection JSCheckFunctionSignatures

import fs from 'fs'
import path from 'path'

if(process.argv.length < 4) {
  console.log('Must specify a root project path and a registry path!')
  process.exit(1)
}

const projectPath = process.argv[2]
const registryPath = process.argv[3]
const packageJsonPath = path.join(projectPath, 'package.json')

if(!fs.existsSync(packageJsonPath)) {
  console.log(`The directory "${projectPath}" is not a root project.`)
  process.exit(1)
}
if(!fs.existsSync(registryPath)) {
  console.log(`No such directory: ${registryPath}`)
  process.exit(1)
}

let packageJson = JSON.parse(fs.readFileSync(packageJsonPath))
let packageName = packageJson.name
if(packageName.includes('/')) {
  packageName = packageName.substring(packageName.indexOf('/') + 1)
}

let packagePath = path.join(registryPath, packageJson.name)
if(!fs.existsSync(packagePath)) process.exit(0)

let fileName = `${packageName}-${packageJson.version}.tgz`
fs.rmSync(path.join(packagePath, fileName), { force: true })

let info = JSON.parse(fs.readFileSync(path.join(packagePath, 'package.json')))
delete info.versions[packageJson.version]
delete info.time[packageJson.version]
delete info['dist-tags']['latest']
delete info['_attachments'][fileName]

fs.writeFileSync(path.join(packagePath, 'package.json'), JSON.stringify(info, null, 4))
