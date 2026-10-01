const DSP={
  cfg:window.DSP_CONFIG||{},
  client:null,
  ready(){return this.cfg.SUPABASE_URL&&this.cfg.SUPABASE_ANON_KEY&&!this.cfg.SUPABASE_URL.includes("PASTE_")&&!this.cfg.SUPABASE_ANON_KEY.includes("PASTE_")},
  async init(){if(!this.ready()){return false}this.client=window.supabase.createClient(this.cfg.SUPABASE_URL,this.cfg.SUPABASE_ANON_KEY);return true},
  esc(v){return String(v??"").replace(/[&<>"']/g,m=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#039;"}[m]))},
  async user(){if(!this.client)return null;const {data}=await this.client.auth.getUser();return data.user||null},
  async profile(){const u=await this.user();if(!u)return null;const {data}=await this.client.from("staff_profiles").select("*").eq("user_id",u.id).maybeSingle();return data||null},
  msg(el,type,text){el.innerHTML='<div class="'+type+'">'+this.esc(text)+'</div>'},
  fmtDate(v){return v?new Date(v).toLocaleString("en-IN",{dateStyle:"medium",timeStyle:"short"}):"—"}
};
