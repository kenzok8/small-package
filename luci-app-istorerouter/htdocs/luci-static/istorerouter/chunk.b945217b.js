import{_ as r,d as u,D as i,a as d,r as h,o as t,c as e,f as n,h as s,F as p,e as _,t as a}from"./index.js";const v={class:"ul-container"},m={class:"ul-container_body"},b={class:"page-table"},f=n("colgroup",null,[n("col"),n("col"),n("col"),n("col")],-1),g=n("thead",null,[n("tr",null,[n("th",null,"Mac"),n("th",null,"IPv4"),n("th",null,"IPv6"),n("th")])],-1),k=n("th",null,null,-1),x=n("th",null,null,-1),B=u({__name:"index",setup(y){const o=i(),c=d(()=>o.device.devices);return h(),(P,C)=>(t(),e("main",null,[n("ul",v,[s(` <div class="ul-container_title">
                <span>DHCP\u8BBE\u5907</span>
            </div> `),n("div",m,[n("table",b,[f,g,n("tbody",null,[(t(!0),e(p,null,_(c.value,l=>(t(),e("tr",null,[n("th",null,a(l.mac),1),n("th",null,a(l.ipv4addr),1),k,x]))),256))])])])]),s(` <ul class="ul-container">
            <div class="ul-container_title">
                <span>\u5C40\u57DF\u7F51\u8BBE\u5907</span>
            </div>
            <div class="ul-container_body">
                <table class="page-table">
                    <colgroup>
                        <col>
                        <col>
                        <col>
                        <col>
                    </colgroup>
                    <thead>
                        <tr>
                            <th>Mac</th>
                            <th>IPv4</th>
                            <th>IPv6</th>
                            <th></th>
                        </tr>
                    </thead>
                    <tbody>
                        <template v-for="(k, mac) in hosts">
                            <tr>
                                <th>
                                    {{ mac }}
                                </th>
                                <th>
                                    <span v-for="item in k.ipaddrs">
                                        {{ item }}
                                        <br>
                                    </span>
                                </th>
                                <th>
                                    <span v-for="item in k.ip6addrs">
                                        {{ item }}
                                        <br>
                                    </span>
                                </th>

                                <th></th>
                            </tr>
                        </template>
                    </tbody>
                </table>
            </div>
        </ul> `)]))}});var F=r(B,[]);export{F as default};
