package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"

	"github.com/hyperledger/fabric-ca/api"
	"github.com/hyperledger/fabric-ca/lib"
)


var baseDir = "/Users/zuvakin/workspace/src/fabric-try/fabric-ca/tool/crypto"

var url = "http://localhost:7054"

func getCaCert(home string) {
	c := lib.Client{
		Config:  &lib.ClientConfig{URL: url},
		HomeDir: filepath.Join(baseDir, home),
	}

	resp, err := c.GetCAInfo(&api.GetCAInfoRequest{})
	if err != nil {
		fmt.Println("get cainfo:", err)
		return
	}

	fmt.Println(resp.CAName, resp.Version)

	//ioutil.WriteFile(filepath.Join(baseDir, home, "msp/cacerts/cacert.pem"), resp.CAChain, 0644)
	//ioutil.WriteFile(filepath.Join(baseDir, home, "msp/IssuerPublicKey"), resp.IssuerPublicKey, 0644)
	//ioutil.WriteFile(filepath.Join(baseDir, home, "msp/IssuerRevocationPublicKey"), resp.IssuerRevocationPublicKey, 0644)
	//
	//os.MkdirAll(filepath.Join(baseDir, home, "msp/admincerts"), 0755)
	//os.MkdirAll(filepath.Join(baseDir, home, "msp/tlscacerts"), 0755)
	//
	//os.RemoveAll(filepath.Join(baseDir, home, "msp/keystore"))
	//os.RemoveAll(filepath.Join(baseDir, home, "msp/signcerts"))
	//os.RemoveAll(filepath.Join(baseDir, home, "msp/user"))
}

func removeAllAffiliation() {
	c := lib.Client{
		Config:  &lib.ClientConfig{URL: url},
		HomeDir: filepath.Join(baseDir, "./imdca"),
	}

	admin, err := c.LoadMyIdentity()
	if err != nil {
		fmt.Println("load my identity:", err)
		return
	}

	_, err = admin.GetAllAffiliations("")
	if err != nil {
		fmt.Println("get affilication error:", err)
		return
	}

	//fmt.Println(affiReply.Name, affiReply.Affiliations)

	remove := func(affiliation string) error {
		req := api.RemoveAffiliationRequest{
			Name:  affiliation,
			Force: true,
		}
		admin.RemoveAffiliation(&req)
		if err != nil {
			fmt.Println("remove fail:", err)
			return err
		}
		return nil
	}

	remove("org1.department1")
	remove("org1.department2")
	remove("org2.department1")
	remove("org1")
	remove("org2")
}

func addAffiliation(affiliation string) {
	c := lib.Client{
		Config:  &lib.ClientConfig{URL: url, CAName:"fabric-imdca-server"},
		HomeDir: filepath.Join(baseDir, "imdca"),
	}

	admin, err := c.LoadMyIdentity()
	if err != nil {
		fmt.Println("load my identity:", err)
		return
	}

	add := func(affiliation string) error {
		req := api.AddAffiliationRequest{
			Name: affiliation,
			CAName:"fabric-imdca-server",
		}
		_, err := admin.AddAffiliation(&req)
		if err != nil {
			fmt.Println("fail to add ", affiliation, "err:", err)
			return err
		}
		fmt.Println("add affiliation ", affiliation, "ok")
		return nil
	}

	add(affiliation)
	//add("com")
	//add("com.example")
	//add("com.example.org1")
	//add("com.example.org2")
}

func register(home, name, pass, roleType, affiliation string, attr []api.Attribute) {
	c := lib.Client{
		Config:  &lib.ClientConfig{URL: url},
		HomeDir: filepath.Join(baseDir, home),
	}

	admin, err := c.LoadMyIdentity()
	if err != nil {
		fmt.Println("load my identity:", err)
		return
	}

	csrInfo := api.CSRInfo{
		Hosts:[]string{name},
		CN: name,
	}

	c.Config.CSR = csrInfo

	req := api.RegistrationRequest{
		Name:           name,
		Type:           roleType,
		Affiliation:    affiliation,
		Secret:         pass,
		MaxEnrollments: 0,
		Attributes:attr,
	}

	resp, err := admin.Register(&req)
	if err != nil {
		fmt.Println("register fail:", err)
		return
	}

	fmt.Println("register ok: ", resp.Secret)
}

func initCA(home, user, pass string ) {
	c := lib.Client{
		Config:  &lib.ClientConfig{URL: url},
		HomeDir: filepath.Join(baseDir, home),
	}

	resp, err := c.Enroll(&api.EnrollmentRequest{Name: user, Secret: pass})
	if err != nil {
		fmt.Println("enroll admin:", err)
		return
	}

	fmt.Println("ca name:", resp.CAInfo.CAName, resp.CAInfo.Version)

	//ioutil.WriteFile(filepath.Join(baseDir, home, "msp/cacerts/cacert.pem"), resp.CAInfo.CAChain, 0644)
	//ioutil.WriteFile(filepath.Join(baseDir, home, "msp/IssuerPublicKey"), resp.CAInfo.IssuerPublicKey, 0644)
	//ioutil.WriteFile(filepath.Join(baseDir, home, "msp/IssuerRevocationPublicKey"), resp.CAInfo.IssuerRevocationPublicKey, 0644)


	//err = resp.Identity.Store()
	//if err != nil {
	//	fmt.Println("store identity error:", err)
	//	return
	//}

	fmt.Println("signcert name:", resp.Identity.GetECert().GetName())
	fmt.Println("signcert cert:", resp.Identity.GetECert().Cert())
	if resp.Identity.GetECert().Key().Private() {
		fmt.Println("private key")
		key := resp.Identity.GetECert().Key()
		d, err := key.Bytes()
		if err != nil {
			fmt.Println("key bytes:", err)
		}

		fmt.Println("prk: ", d)
		fmt.Println("SKI:", resp.Identity.GetECert().Key().SKI())

		enrollID, _ := resp.Identity.GetX509Credential().EnrollmentID()
		fmt.Println("enroll id:", enrollID)
		v, err := resp.Identity.GetX509Credential().Val()
		if err != nil {
			fmt.Println("get value:", err)
			return
		}
		fmt.Println(v)
	}
	err = ioutil.WriteFile(filepath.Join(baseDir, "temp.crt"), resp.Identity.GetECert().Cert(), 0644)
	if err != nil {
		fmt.Println("write error:", err)
	}
}

func enroll(home, user, pass, roleType string) {
	homeDir := ""
	if roleType == "admin" {
		homeDir = filepath.Join(baseDir, home, "users")
	} else if roleType == "peer" {
		homeDir = filepath.Join(baseDir, home, "peers")
	} else if roleType == "orderer" {
		homeDir = filepath.Join(baseDir, home, "orderers")
	} else if roleType == "caadmin" {
		homeDir = filepath.Join(baseDir, home)
	} else {
		fmt.Println("invalid roletype:", roleType)
		return
	}

	c := lib.Client{
		Config:  &lib.ClientConfig{URL: url, CAName: "fabric-ca-server"},
		HomeDir: filepath.Join(homeDir, user),
	}

	//req := &api.EnrollmentRequest{Name: user, Secret: pass}

	csrInfo := api.CSRInfo{
		Hosts:[]string{user},
	}

	resp, err := c.Enroll(&api.EnrollmentRequest{Name: user, Secret: pass, CSR:&csrInfo})
	if err != nil {
		fmt.Println("enroll admin:", err)
		return
	}

	ioutil.WriteFile(filepath.Join(homeDir, user, "msp/cacerts/cacert.pem"), resp.CAInfo.CAChain, 0644)
	ioutil.WriteFile(filepath.Join(homeDir, user, "msp/IssuerPublicKey"), resp.CAInfo.IssuerPublicKey, 0644)
	ioutil.WriteFile(filepath.Join(homeDir, user, "msp/IssuerRevocationPublicKey"), resp.CAInfo.IssuerRevocationPublicKey, 0644)

	err = resp.Identity.Store()
	if err != nil {
		fmt.Println("store identity error:", err)
		return
	}

	fmt.Println("resp signcer: ", resp.Identity.GetECert().Cert())
	os.MkdirAll(filepath.Join(homeDir, user, "msp/admincerts"), 0755)
	os.MkdirAll(filepath.Join(homeDir, user, "msp/tlscacerts"), 0755)

	if roleType == "admin" {
		adminCert := filepath.Join(homeDir, user, "msp/signcerts")
		//caCert := filepath.Join(baseDir, home, "msp/cacerts")
		copyFile(adminCert, filepath.Join(homeDir, user, "msp/admincerts"))
		copyFile(adminCert, filepath.Join(baseDir, home, "msp/admincerts"))
		//copyFile(caCert, filepath.Join(homeDir, user, "msp/cacerts"))
	} else if roleType == "orderer" || roleType == "peer" {
		adminCert := filepath.Join(baseDir, home,  "msp/admincerts")
		copyFile(adminCert, filepath.Join(homeDir, user, "msp/admincerts"))
	}

	os.RemoveAll(filepath.Join(homeDir, user, "msp/user"))
}

func enrollTLS(home, user, pass, roleType string) {
	c := lib.Client{
		Config:  &lib.ClientConfig{URL: url, CAName: "fabric-ca-server", MSPDir:filepath.Join(baseDir, home, "tls")},
		HomeDir: filepath.Join(baseDir, home),
	}

	csrInfo := api.CSRInfo{
		Hosts:[]string{user},
		CN:user,
	}

	c.Config.CSR = csrInfo
	req := &api.EnrollmentRequest{Name:user, Secret:pass, Profile:"tls", CSR:&csrInfo}

	resp, err := c.Enroll(req)
	if err != nil {
		fmt.Println("enroll fail:", err)
		return
	}

	certFile := ""
	keyFile := ""
	if roleType == "admin" {
		certFile = "client.crt"
		keyFile = "client.key"
	} else if roleType == "peer" || roleType == "orderer" {
		certFile = "server.crt"
		keyFile = "server.key"
	} else {
		fmt.Println("invliad role type:", roleType)
		return
	}
	ioutil.WriteFile(filepath.Join(baseDir, home, "tls", certFile), resp.Identity.GetECert().Cert(), 0644)
	ioutil.WriteFile(filepath.Join(baseDir, home, "tls/ca.crt"), resp.CAInfo.CAChain, 0644)

	copyFile(filepath.Join(baseDir, home, "tls/keystore"), filepath.Join(baseDir, home, "tls", keyFile))
	copyFile(filepath.Join(baseDir, home, "tls/ca.crt"), filepath.Join(baseDir, home, "msp/tlscacerts"))

	os.RemoveAll(filepath.Join(baseDir, home, "tls/cacerts"))
	os.RemoveAll(filepath.Join(baseDir, home, "tls/keystore"))
	os.RemoveAll(filepath.Join(baseDir, home, "tls/signcerts"))
	os.RemoveAll(filepath.Join(baseDir, home, "tls/user"))
}

func applyOrgCa(home, name, pass string) {
	attributes := []api.Attribute{
			{
				Name:"hf.Registrar.Roles",
				Value:"client,orderer,peer,user",
			},
			{
				Name:"hf.Registrar.DelegateRoles",
				Value:"client,orderer,peer,user",
			},
			{
				Name: "hf.Registrar.Attributes",
				Value:"*",
			},
			{
				Name: "hf.GenCRL",
				Value:"true",
			},
			{
				Name: "hf.Revoker",
				Value: "true",
			},
			{
				Name: "hf.AffiliationMgr",
				Value: "true",
			},
			{
				Name: "role",
				Value:"admin",
				ECert:true,
			},
	}
	register("./crypto/admin", name, pass, "client", "com", attributes)
	enroll(home, name, pass, "admin")
	copyFile(filepath.Join(baseDir, home, "msp/keystore"), filepath.Join(baseDir, home))
	copyFile(filepath.Join(baseDir, home, "msp/signcerts"), filepath.Join(baseDir, home))
	os.RemoveAll(filepath.Join(baseDir, home, "msp"))
}

func newPeerAttr(roleType string) []api.Attribute {
	return []api.Attribute{
			{
				Name:  "role",
				Value: roleType,
				ECert: true,
			},
		}
}

func newClientAttr() []api.Attribute {
	return []api.Attribute{
		{
			Name:"hf.Registrar.Roles",
			Value:"client,orderer,peer,user",
		},
		{
			Name:"hf.Registrar.DelegateRoles",
			Value:"client,orderer,peer,user",
		},
		{
			Name: "hf.Registrar.Attributes",
			Value:"*",
		},
		{
			Name: "hf.GenCRL",
			Value:"true",
		},
		{
			Name: "hf.Revoker",
			Value: "true",
		},
		{
			Name: "hf.AffiliationMgr",
			Value: "true",
		},
		{
			Name: "role",
			Value:"admin",
			ECert:true,
		},
	}
}

func copyFile(src, dst string) {
	fmt.Println("from:", src, "to:", dst)
	filename := ""
	copyfiles := func(srcFile, dstFile string) {
		srcBytes, err := ioutil.ReadFile(srcFile)
		if err != nil {
			fmt.Println("read file error:", err)
			os.Exit(1)
		}

		f, err := os.Stat(dst)
		if err != nil {
			//fmt.Println("file not exist:", err)
			f, err := os.Create(dst)
			if err != nil {
				fmt.Println("create file:", err)
				os.Exit(1)
			}
			f.Write(srcBytes)
			f.Close()
			return
			//os.Exit(1)
		}

		if f.IsDir() {
			ioutil.WriteFile(filepath.Join(dst, filename), srcBytes, 0644)
		} else {
			ioutil.WriteFile(dst, srcBytes, 0644)
		}

		return
	}

	finfo, err := os.Stat(src)
	if err != nil {
		fmt.Println("fail to get file:", err)
		os.Exit(1)
	}
	if !finfo.IsDir() {
		copyfiles(src, dst)
		return
	}

	err = filepath.Walk(src, func(path string, f os.FileInfo, err error) error {
			if f == nil {
				return err
			}
			if f.IsDir() {
				return nil
			}
			filename = f.Name()
			copyfiles(filepath.Join(src, f.Name()), dst)
			return nil
	})
	if err != nil {
		fmt.Println("copy error:", err)
		os.Exit(1)
	}
}

func main() {
	initCA("./imdca", "admin", "adminpw")
	removeAllAffiliation()

	//getCaCert("./crypto/example.com/msp")
	//enroll("./crypto/admin", "admin", "adminpw")

	//applyOrgCa("./crypto/ordererOrgs/example.com/ca", "example.com", "123456")
	//applyOrgCa("./crypto/peerOrgs/org1.example.com/ca", "org1.example.com", "123456")
	//applyOrgCa("./crypto/peerOrgs/org2.example.com/ca", "org2.example.com", "123456")

	//getCaCert("./temp")
	//getCaCert("./crypto/peerOrgs/org1.example.com")
	//getCaCert("./crypto/peerOrgs/org2.example.com")

	//addAffiliation("com")
	//addAffiliation("com.example")
	//addAffiliation("com.example.org1")

	//register("./imdca", "Admin@example.com", "123456", "client", "com.example", newClientAttr())
	//register("./crypto/admin", "Admin@org1.example.com", "123456", "client", "com.example.org1", newClientAttr())
	//register("./crypto/admin", "Admin@org2.example.com", "123456", "client", "com.example.org2", newClientAttr())

	//enroll("./ordererOrgs/example.com", "Admin@example.com", "123456", "admin")
	//enroll("./crypto/peerOrgs/org1.example.com", "Admin@org1.example.com", "123456", "admin")
	//enroll("./crypto/peerOrgs/org2.example.com", "Admin@org2.example.com", "123456", "admin")

	//register("./crypto/ordererOrgs/example.com/users/Admin@example.com", "orderer.example.com", "123456", "orderer", "com.example", newPeerAttr("orderer"))
	//register("./crypto/peerOrgs/org1.example.com/users/Admin@org1.example.com", "peer0.org1.example.com", "123456", "peer", "com.example.org1", newPeerAttr("peer"))
	//register("./crypto/peerOrgs/org2.example.com/users/Admin@org2.example.com", "peer0.org2.example.com", "123456", "peer", "com.example.org2", newPeerAttr("peer"))

	//enroll("./crypto/ordererOrgs/example.com", "orderer.example.com", "123456", "orderer")
	//enroll("./crypto/peerOrgs/org1.example.com", "peer0.org1.example.com", "123456", "peer")
	//enroll("./crypto/peerOrgs/org2.example.com", "peer0.org2.example.com", "123456", "peer")

	//genOrgMSP("./crypto/ordererOrgs/example.com", "Admin@example.com")
	//genOrgMSP("./crypto/peerOrgs/org1.example.com", "Admin@org1.example.com")
	//genOrgMSP("./crypto/peerOrgs/org2.example.com", "Admin@org2.example.com")

	//enrollTLS("./crypto/ordererOrgs/example.com/users/Admin@example.com", "Admin@example.com", "123456", "admin")
	//enrollTLS("./crypto/ordererOrgs/example.com/orderers/orderer.example.com", "orderer.example.com", "123456", "orderer")
	//enrollTLS("./crypto/peerOrgs/org1.example.com/users/Admin@org1.example.com", "Admin@org1.example.com", "123456", "admin")
	//enrollTLS("./crypto/peerOrgs/org1.example.com/peers/peer0.org1.example.com", "peer0.org1.example.com", "123456", "peer")
	//enrollTLS("./crypto/peerOrgs/org2.example.com/users/Admin@org2.example.com", "Admin@org2.example.com", "123456", "admin")
	//enrollTLS("./crypto/peerOrgs/org2.example.com/peers/peer0.org2.example.com", "peer0.org2.example.com", "123456", "peer")

	//enroll("./crypto/test", "peer0.org2.example.com", "123456", "admin")

	//==================  k8s =====================
	//addAffiliation("svc")
	//addAffiliation("svc.cluster")
	//addAffiliation("svc.cluster.local")
	//addAffiliation("svc.cluster.local.orderers")
	//addAffiliation("svc.cluster.local.org1")
	//addAffiliation("svc.cluster.local.org2")

	//getCaCert("./k8s/ordererOrganizations/orderers.svc.cluster.local")
	//getCaCert("./k8s/peerOrganizations/org1.svc.cluster.local")
	//getCaCert("./k8s/peerOrganizations/org2.svc.cluster.local")

	//register("./crypto/admin", "Admin@orderers.svc.cluster.local", "123456", "client", "svc.cluster.local.orderers", newClientAttr())
	//register("./crypto/admin", "Admin@org1.svc.cluster.local", "123456", "client", "svc.cluster.local.org1", newClientAttr())
	//register("./crypto/admin", "Admin@org2.svc.cluster.local", "123456", "client", "svc.cluster.local.org2", newClientAttr())

	//enroll("./k8s/ordererOrganizations/orderers.svc.cluster.local", "Admin@orderers.svc.cluster.local", "123456", "admin")
	//enroll("./k8s/peerOrganizations/org1.svc.cluster.local", "Admin@org1.svc.cluster.local", "123456", "admin")
	//enroll("./k8s/peerOrganizations/org2.svc.cluster.local", "Admin@org2.svc.cluster.local", "123456", "admin")

	//register("./k8s/ordererOrganizations/orderers.svc.cluster.local/users/Admin@orderers.svc.cluster.local", "ord1-baas-fabric-orderer.orderers.svc.cluster.local", "123456", "orderer", "svc.cluster.local.orderers", newPeerAttr("orderer"))
	//register("./k8s/peerOrganizations/org1.svc.cluster.local/users/Admin@org1.svc.cluster.local", "peer0-baas-fabric-peer.org1.svc.cluster.local", "123456", "peer", "svc.cluster.local.org1", newPeerAttr("peer"))
	//register("./k8s/peerOrganizations/org2.svc.cluster.local/users/Admin@org2.svc.cluster.local", "peer1-baas-fabric-peer.org2.svc.cluster.local", "123456", "peer", "svc.cluster.local.org2", newPeerAttr("peer"))

	//enroll("./k8s/ordererOrganizations/orderers.svc.cluster.local", "ord1-baas-fabric-orderer.orderers.svc.cluster.local", "123456", "orderer")
	//enroll("./k8s/peerOrganizations/org1.svc.cluster.local", "peer0-baas-fabric-peer.org1.svc.cluster.local", "123456", "peer")
	//enroll("./k8s/peerOrganizations/org2.svc.cluster.local", "peer1-baas-fabric-peer.org2.svc.cluster.local", "123456", "peer")

	//enrollTLS("./k8s/ordererOrganizations/orderers.svc.cluster.local/users/Admin@orderers.svc.cluster.local", "Admin@orderers.svc.cluster.local", "123456", "admin")
	//enrollTLS("./k8s/ordererOrganizations/orderers.svc.cluster.local/orderers/ord1-baas-fabric-orderer.orderers.svc.cluster.local", "ord1-baas-fabric-orderer.orderers.svc.cluster.local", "123456", "orderer")
	//enrollTLS("./k8s/peerOrganizations/org1.svc.cluster.local/users/Admin@org1.svc.cluster.local", "Admin@org1.svc.cluster.local", "123456", "admin")
	//enrollTLS("./k8s/peerOrganizations/org1.svc.cluster.local/peers/peer0-baas-fabric-peer.org1.svc.cluster.local", "peer0-baas-fabric-peer.org1.svc.cluster.local", "123456", "peer")
	//enrollTLS("./k8s/peerOrganizations/org2.svc.cluster.local/users/Admin@org2.svc.cluster.local", "Admin@org2.svc.cluster.local", "123456", "admin")
	//enrollTLS("./k8s/peerOrganizations/org2.svc.cluster.local/peers/peer1-baas-fabric-peer.org2.svc.cluster.local", "peer1-baas-fabric-peer.org2.svc.cluster.local", "123456", "peer")


	//=============== test ==========
	//addAffiliation("com.example.org3")
	//getCaCert("./crypto/peerOrgs/org3.example.com")
	//register("./crypto/admin", "Admin@org3.example.com", "123456", "client", "com.example.org3", newClientAttr())
	//enroll("./crypto/peerOrgs/org3.example.com", "Admin@org3.example.com", "123456", "admin")

	//================= test 2 =============
	//addAffiliation("baas")
	//addAffiliation("baas.example")
	//addAffiliation("baas.example.org1")
	//addAffiliation("baas.example.org2")
	//
	//getCaCert("./k8s-baas/ordererOrganizations/baas.example")
	//getCaCert("./k8s-baas/peerOrganizations/baas.example.org1")
	//getCaCert("./k8s-baas/peerOrganizations/baas.example.org2")
	//
	//register("./crypto/admin", "Admin@orderers.svc.cluster.local", "123456", "client", "baas.example", newClientAttr())
	//register("./crypto/admin", "Admin@org1.svc.cluster.local", "123456", "client", "baas.example.org1", newClientAttr())
	//register("./crypto/admin", "Admin@org2.svc.cluster.local", "123456", "client", "baas.example.org2", newClientAttr())
	//
	//enroll("./k8s-baas/ordererOrganizations/baas.example", "Admin@orderers.svc.cluster.local", "123456", "admin")
	//enroll("./k8s-baas/peerOrganizations/baas.example.org1", "Admin@org1.svc.cluster.local", "123456", "admin")
	//enroll("./k8s-baas/peerOrganizations/baas.example.org2", "Admin@org2.svc.cluster.local", "123456", "admin")
	//
	//register("./k8s-baas/ordererOrganizations/baas.example/users/Admin@orderers.svc.cluster.local", "ord1-baas-fabric-orderer.orderers.svc.cluster.local", "123456", "orderer", "baas.example", newPeerAttr("orderer"))
	//register("./k8s-baas/peerOrganizations/baas.example.org1/users/Admin@org1.svc.cluster.local", "peer0-baas-fabric-peer.org1.svc.cluster.local", "123456", "peer", "baas.example.org1", newPeerAttr("peer"))
	//register("./k8s-baas/peerOrganizations/baas.example.org2/users/Admin@org2.svc.cluster.local", "peer1-baas-fabric-peer.org2.svc.cluster.local", "123456", "peer", "baas.example.org2", newPeerAttr("peer"))
	//
	//enroll("./k8s-baas/ordererOrganizations/baas.example", "ord1-baas-fabric-orderer.orderers.svc.cluster.local", "123456", "orderer")
	//enroll("./k8s-baas/peerOrganizations/baas.example.org1", "peer0-baas-fabric-peer.org1.svc.cluster.local", "123456", "peer")
	//enroll("./k8s-baas/peerOrganizations/baas.example.org2", "peer1-baas-fabric-peer.org2.svc.cluster.local", "123456", "peer")
	//
	//enrollTLS("./k8s-baas/ordererOrganizations/baas.example/users/Admin@orderers.svc.cluster.local", "Admin@orderers.svc.cluster.local", "123456", "admin")
	//enrollTLS("./k8s-baas/ordererOrganizations/baas.example/orderers/ord1-baas-fabric-orderer.orderers.svc.cluster.local", "ord1-baas-fabric-orderer.orderers.svc.cluster.local", "123456", "orderer")
	//enrollTLS("./k8s-baas/peerOrganizations/baas.example.org1/users/Admin@org1.svc.cluster.local", "Admin@org1.svc.cluster.local", "123456", "admin")
	//enrollTLS("./k8s-baas/peerOrganizations/baas.example.org1/peers/peer0-baas-fabric-peer.org1.svc.cluster.local", "peer0-baas-fabric-peer.org1.svc.cluster.local", "123456", "peer")
	//enrollTLS("./k8s-baas/peerOrganizations/baas.example.org2/users/Admin@org2.svc.cluster.local", "Admin@org2.svc.cluster.local", "123456", "admin")
	//enrollTLS("./k8s-baas/peerOrganizations/baas.example.org2/peers/peer1-baas-fabric-peer.org2.svc.cluster.local", "peer1-baas-fabric-peer.org2.svc.cluster.local", "123456", "peer")

}
