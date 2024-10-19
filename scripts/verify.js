#!/usr/bin/env node
(() => {
  require('dotenv').config()
  const shell = require('shelljs')
  const gemforgeConfig = require('../gemforge.config.cjs')

  const deploymentInfo = require('../gemforge.deployments.json')

  const target = process.env.GEMFORGE_DEPLOY_TARGET
  if (!target) {
    throw new Error('GEMFORGE_DEPLOY_TARGET env var not set')
  }

  // skip localhost
  if (target === 'local') {
    console.log('Skipping verification on local')
    return
  }

  const verifierUrls = {
    base_sepolia: 'https://api-sepolia.basescan.org/api',
    base: 'https://api.basescan.org/api',
  }

  console.log(`Verifying for target ${target} ...`)

  const contracts = (deploymentInfo[target] || {}).contracts || []

  const _exec = (cmd) => {
    console.log(`---> ${cmd}`)
    return shell.exec(cmd).stdout.trim()
  }

  for (let { name, onChain } of contracts) {
    console.log(`\n\nVerifying ${name} ...`)
    
    let args = '0x'

    if (onChain.constructorArgs.length) {
      args = _exec(`cast abi-encode "constructor(address)" ${onChain.constructorArgs.join(' ')}`)
    }

    console.log(`Verifying ${name} at ${onChain.address} with args ${args}`)

    _exec(`forge verify-contract --chain ${deploymentInfo[target].chainId} --verifier etherscan --verifier-url ${verifierUrls[target]} --etherscan-api-key ${process.env.BASESCAN_API_KEY} --num-of-optimizations 200 --watch --constructor-args ${args} ${onChain.address} ${name} --compiler-version ${gemforgeConfig.solc.version}`)
  }
})()
