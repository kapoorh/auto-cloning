const controller = {};
var exec = require('child_process').exec;
const fs = require('fs');

controller.clonevm = (req, res) => {	
    createvmclone(req, res);
};

async function createvmclone(req, res)
{	
	var sourceResourceGroupName =  req.body.srcslot;	
	var targetResourceGroupName =  req.body.tgtslot;
	console.log(sourceResourceGroupName);
	console.log(targetResourceGroupName);
	var timeStamp = new Date().getTime();
		
	const promiseClone = createScriptFile(timeStamp,sourceResourceGroupName, targetResourceGroupName);
	Promise.all([promiseClone]).then(function(values) {
		fs.unlinkSync(values[0]);
		console.log('Cloning Completed.');    
  }).catch(error => {
    console.log(error);    
  }); 
  
  res.json({"sourceResourceGroupName": sourceResourceGroupName,"targetResourceGroupName":targetResourceGroupName});
}

async function createScriptFile(timeStamp,sourceResourceGroupName, targetResourceGroupName){
	var fileName = "clone-vm-" + timeStamp + ".ps1";
	var currentPath = process.cwd();
	var cmd = "copy " + currentPath + "\\ps-scripts\\clonevm.ps1" + " " + currentPath+"\\ps-scripts\\"+ fileName ;	
	var scriptFilePath = ".\\ps-scripts\\"+ fileName;
	console.log(scriptFilePath);
	await execCmd(cmd);
	const prepareScriptResp = await prepareScript(scriptFilePath, sourceResourceGroupName, targetResourceGroupName);		
	return scriptFilePath;
}

async function prepareScript(scriptFilePath, sourceResourceGroupName, targetResourceGroupName){
  var originalContent = await readFile(scriptFilePath);
  var modifiedContent = originalContent.replace(/###sourceResourceGroupNameVar###/g, sourceResourceGroupName);
  await writeFile(scriptFilePath, modifiedContent);
  var originalContent1 = await readFile(scriptFilePath);
  var modifiedContent1 = originalContent1.replace(/###targetResourceGroupNameVar###/g, targetResourceGroupName);
  await writeFile(scriptFilePath, modifiedContent1);
  const runCmd = 'powershell.exe ' + scriptFilePath;
  await execCmd(runCmd);
  return modifiedContent1;
}

async function execCmd(cmd) {
	return new Promise((resolve, reject) => {
			exec(cmd, {maxBuffer: Infinity}, (error, stdout, stderr) => {
					if (error)  reject(error);
					if (stderr)  reject(stderr);
					resolve(stdout);
			});
	});
}

async function readFile(scriptFilePath) {
	return new Promise((resolve, reject) => {
			fs.readFile(scriptFilePath, 'utf8', (err, data) => {
					if (err) reject(err);
					else resolve(data);
			});
	});
}

async function writeFile(scriptFilePath, data) {
	return new Promise((resolve, reject) => {
			fs.writeFile(scriptFilePath, data, 'utf8', err => {
					if (err) reject(err);
					else resolve(data);
			});
	});
}

module.exports = controller;