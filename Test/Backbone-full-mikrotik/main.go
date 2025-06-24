package main

import (
        "io"
        "context"
        "crypto/rand"
        "encoding/base64"
        "strconv"
        "fmt"
        "github.com/apenella/go-ansible/v2/pkg/playbook"
        "github.com/gin-gonic/gin"
        "gopkg.in/yaml.v2"
        "net"
        "net/http"
        "os"
        "github.com/netbox-community/go-netbox/v4"
        "github.com/joho/godotenv"
)

type postvm struct {
        Vdom    string          `json:"Vdom"`
}


type GenerateLNS struct {
        AS                    string    `json:"AS"`
        IPLoopback            net.IP    `json:"IPLoopback"`
}


func main() {
        router := gin.Default()
        router.POST("/conflns", confLNS)
        router.POST("/postlns", postLNS)
        router.Run(":8081")
}


func confLNS (c *gin.Context) {

        godotenv.Load(".env")

        url := os.Getenv("NETBOX_URL")
        token := os.Getenv("NETBOX_TOKEN")

        var jsonInput postvm

        if err := c.ShouldBindJSON(&jsonInput); err != nil {
                c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
                return
        }

        ctx := context.Background()

        client := netbox.NewAPIClientFor(url, token)

        vm := GenerateLNS{
        }

        resvm, _, err := client.VirtualizationAPI.VirtualizationVirtualMachinesList(ctx).Name([]string{jsonInput.Vdom}).Execute()
        if err != nil {
                fmt.Println("Erreur le tenant n'existe pas: ", jsonInput.Vdom, err)
                return
        }

        vmID := resvm.Results[0].Id

        descriptionas := jsonInput.Vdom + "_AS"

        asRequest := []netbox.ASNRequest{
                {
                        Description: &descriptionas,
                },
        }

        resas, resp, err := client.IpamAPI.IpamAsnRangesAvailableAsnsCreate(ctx, int32(2)).ASNRequest(asRequest).Execute()

        if err != nil {
                body, _ := io.ReadAll(resp.Body)
                fmt.Println("Erreur création de l'AS: ", err, string(body))
                return
        }

        vm.AS = strconv.FormatInt(resas[0].Asn, 10)

        descriptionlo := "By-api"

        IPRequest := netbox.IPAddressRequest{
                Description: &descriptionlo,
        }

        resip, resp, err := client.IpamAPI.IpamPrefixesAvailableIpsCreate(ctx, int32(65)).IPAddressRequest([]netbox.IPAddressRequest{IPRequest}).Execute()

        if err != nil {
                body, _ := io.ReadAll(resp.Body)
                fmt.Println("Erreur création de l'adresse: ", err, string(body))
                return
        }

        addrlo := resip[0].Address
        vm.IPLoopback, _, _ = net.ParseCIDR(addrlo)

        customFields := map[string]interface{}{
                "lns": vm,
        }

        patchRequest := netbox.PatchedWritableVirtualMachineWithConfigContextRequest{
                CustomFields: customFields,
        }

        client.VirtualizationAPI.VirtualizationVirtualMachinesPartialUpdate(ctx, vmID).PatchedWritableVirtualMachineWithConfigContextRequest(patchRequest).Execute()
}

func postLNS(c *gin.Context) {

        godotenv.Load(".env")

        url := os.Getenv("NETBOX_URL")
        token := os.Getenv("NETBOX_TOKEN")

        var jsonInput postvm

        if err := c.ShouldBindJSON(&jsonInput); err != nil {
                 c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
                 return
        }

        ctx := context.Background()

        client := netbox.NewAPIClientFor(url, token)

        res, _, _ := client.VirtualizationAPI.VirtualizationVirtualMachinesList(ctx).Name([]string{jsonInput.Vdom}).Execute()

        configLns := res.Results[0].CustomFields["lns"].(map[string]interface{})

        configLns["Customer"] = jsonInput.Vdom

        yamlData, err := yaml.Marshal(&configLns)
        if err != nil {
                c.Data(http.StatusOK, "text/plain; charset=utf-8", []byte("Erreur dans la translation en YAML"))
                return
        }

        tmpFile, err := os.CreateTemp("", "lns_vars_*.yml")
        if err != nil {
                c.Data(http.StatusOK, "text/plain; charset=utf-8", []byte("Erreur dans la création du fichier var"))
                return
        }
        defer os.Remove(tmpFile.Name())

        tmpFile.Write(yamlData)
        tmpFile.Close()

        ansiblePlaybookOptions := &playbook.AnsiblePlaybookOptions{
                Inventory:      "/etc/ansible/host",
                ExtraVarsFile:  []string{"@" + tmpFile.Name()},
        }

        err = playbook.NewAnsiblePlaybookExecute("/etc/ansible/playbook/MPLS-MK.yml").
                WithPlaybookOptions(ansiblePlaybookOptions).
                Execute(context.TODO())

        if err != nil {
                c.Data(http.StatusOK, "text/plain; charset=utf-8", []byte("Erreur dans l'execution du playbook"))
                return
        }

        c.Data(http.StatusOK, "text/plain; charset=utf-8", []byte("Playbook ansible pour création du MPLS du client bien lancé et executé"))

}
