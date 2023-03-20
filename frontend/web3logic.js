function main () {
  const btnConnect = document.querySelector('#btn_connect')
  btnConnect.addEventListener('click', _e => {
    connect().catch(console.error)
  })
  const btnSend = document.querySelector('#btn_send')
  btnSend.addEventListener('click', _e => {
    sendMoney().catch(console.error)
  })
}

document.addEventListener('DOMContentLoaded', () => main())
const accountElement = document.getElementById('account')
const balanceElement = document.getElementById('balance')

async function fetchAbi () {
  const resp = await fetch('./erc20_abi.json')
  return await resp.json()
}

// connect with web3 wallet
async function connect () {
  if (window.ethereum) {
    await window.ethereum.request({ method: 'eth_requestAccounts' })
  } else {
    console.log('No wallet')
  }
}

// Send money function
async function sendMoney () {
  const error = document.getElementById('err')
  error.style.display = 'none'
  const receiver = document.getElementById('receiver').value
  const amount = document.getElementById('amount').value
  // Validate input
  if (!receiver || !amount) {
    alert('Please enter a receiver and amount')
    return
  }
  const abi = await fetchAbi()

  const accounts = await ethereum.request({
    method: 'eth_requestAccounts'
  })
  const account = accounts[0]
  console.log(account)
  window.ethereum.on('accountsChanged', function (accounts) {
    console.log(accounts[0])
  })
  console.log(accounts)
  if (accounts.length == 0) {
    connect()
  }
  window.web3 = new Web3(window.ethereum)
  const contract = new web3.eth.Contract(abi, '0xdAC17F958D2ee523a2206206994597C13D831ec7', {
    from: account // default from address
  })
  // Validate amount
  const balance = await contract.methods.balanceOf(account).call()
  balanceElement.textContent = balance
  accountElement.textContent = account
  console.log(balance)
  if (balance >= amount) {
    await contract.methods.transfer(receiver, amount).send()
  } else {
    error.style.display = 'block'
    error.textContent = 'Not enough funds'
  }
}
