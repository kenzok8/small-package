var g=Object.defineProperty;var y=Object.getOwnPropertySymbols;var w=Object.prototype.hasOwnProperty,A=Object.prototype.propertyIsEnumerable;var C=(o,u,s)=>u in o?g(o,u,{enumerable:!0,configurable:!0,writable:!0,value:s}):o[u]=s,k=(o,u)=>{for(var s in u||(u={}))w.call(u,s)&&C(o,s,u[s]);if(y)for(var s of y(u))A.call(u,s)&&C(o,s,u[s]);return o};var b=(o,u,s)=>new Promise((i,t)=>{var p=d=>{try{c(s.next(d))}catch(l){t(l)}},m=d=>{try{c(s.throw(d))}catch(l){t(l)}},c=d=>d.done?i(d.value):Promise.resolve(d.value).then(p,m);c((s=s.apply(o,u)).next())});import{d as T,s as E,j as U,v as q,o as _,c as f,a as e,x as r,A as D,F as V,y as P,z as x,m as B,l as G,B as H,C as M,T as F}from"./index.js?v=6248f3bd";import{i as v}from"./chunk.6d3585bb.js";const L=["onSubmit"],N=e("div",{class:"label-name"},[e("span",null,"\u5185\u7F51\u5730\u5740")],-1),R={class:"label-value"},j=e("div",{class:"label-name"},[e("span",null,"\u5B50\u7F51\u63A9\u7801")],-1),z={class:"label-value"},O=e("div",{class:"label-name"},[e("span",null,"DHCP\u670D\u52A1")],-1),$={class:"label-value"},J={class:"label-flex"},K=e("div",{class:"label-name"},[e("span",null,"IP\u6C60\u8D77\u59CB\u5730\u5740")],-1),Q={class:"label-value"},W=e("div",{class:"label-name"},[e("span",null,"IP\u6C60\u7ED3\u675F\u5730\u5740")],-1),X={class:"label-value"},Y={class:"label-btns"},Z=["disabled"],ee={key:2,class:"label-msg"},ue=T({__name:"index",setup(o){return b(this,null,function*(){let u,s;const i=E(""),t=U({lanIp:"",netMask:"255.255.255.0",enableDhcp:!1,dhcpStart:"",dhcpEnd:""}),p=E(!1),m=E(!1),c=()=>b(this,null,function*(){p.value=!0;const l=yield M.Guide.GetLan.GET();if(l.data){const{result:a}=l.data;a&&(t.lanIp=a.lanIp,t.netMask=a.netMask,m.value=a.enableDhcp||!1,t.dhcpStart=a.dhcpStart,t.dhcpEnd=a.dhcpEnd,a.lanIp,location.hostname)}p.value=!1});[u,s]=q(()=>c()),yield u,s();const d=()=>b(this,null,function*(){const l=k({},t);if(!v.isValidIP(l.lanIp)){F.Error("IPv4\u5730\u5740\u683C\u5F0F\u9519\u8BEF");return}if(!v.isValidMask(l.netMask)){F.Error("IPv4\u5B50\u7F51\u63A9\u7801\u683C\u5F0F\u9519\u8BEF");return}if(l.enableDhcp&&!v.isValidIP(l.dhcpStart)||!v.isValidIP(l.dhcpEnd)||!v.isValidMaskRange(l.lanIp,l.netMask,l.dhcpStart,l.dhcpEnd)){F.Error("DHCP\u7684IP\u6C60\u683C\u5F0F\u9519\u8BEF\u6216\u8D85\u51FA\u5B50\u7F51\u8303\u56F4");return}const a=F.Loading("\u6B63\u5728\u914D\u7F6E,\u8BF7\u7A0D\u7B49\u2026");let n=!1;try{const h=yield M.Guide.LanIp.POST(l);if(h.data){const{result:ae,success:S,error:I}=h.data;if(I){i.value=I;return}(S||0)==0&&(n=!0)}}catch(h){i.value=h}finally{a.Close()}n&&(i.value=`\u66F4\u65B0\u6210\u529F,\u8BF7\u8FDB\u5165 ${l.lanIp} \u8DEF\u7531\u5668\u5730\u5740`)});return(l,a)=>(_(),f("form",{class:"form-container",onSubmit:H(d,["prevent"])},[N,e("div",R,[r(e("input",{type:"text",placeholder:"192.168.100.1","onUpdate:modelValue":a[0]||(a[0]=n=>t.lanIp=n),required:""},null,512),[[D,t.lanIp,void 0,{trim:!0}]])]),j,e("div",z,[r(e("input",{type:"text",placeholder:"255.255.255.0","onUpdate:modelValue":a[1]||(a[1]=n=>t.netMask=n),required:""},null,512),[[D,t.netMask,void 0,{trim:!0}]])]),m.value?(_(),f(V,{key:0},[O,e("div",$,[e("div",J,[e("label",null,[r(e("input",{type:"radio",value:!1,"onUpdate:modelValue":a[2]||(a[2]=n=>t.enableDhcp=n)},null,512),[[P,t.enableDhcp]]),x("\u4FDD\u6301DHCP")]),e("label",null,[r(e("input",{type:"radio",value:!0,"onUpdate:modelValue":a[3]||(a[3]=n=>t.enableDhcp=n)},null,512),[[P,t.enableDhcp]]),x("\u4FEE\u6539DHCP")])])])],64)):B("",!0),t.enableDhcp?(_(),f(V,{key:1},[K,e("div",Q,[r(e("input",{type:"text",placeholder:"192.168.100.100","onUpdate:modelValue":a[4]||(a[4]=n=>t.dhcpStart=n),required:""},null,512),[[D,t.dhcpStart,void 0,{trim:!0}]])]),W,e("div",X,[r(e("input",{type:"text",placeholder:"192.168.100.100","onUpdate:modelValue":a[5]||(a[5]=n=>t.dhcpEnd=n),required:""},null,512),[[D,t.dhcpEnd,void 0,{trim:!0}]])])],64)):B("",!0),e("div",Y,[e("button",{class:"sumbit",disabled:p.value},"\u4FDD\u5B58",8,Z)]),i.value?(_(),f("div",ee,[e("span",null,G(i.value),1)])):B("",!0)],40,L))})}});export{ue as default};