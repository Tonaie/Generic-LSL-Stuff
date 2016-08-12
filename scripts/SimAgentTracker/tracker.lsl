/*
  
  This script lets you track people entering or leaving a parcel, and sending you an IM whenever that occurs.
  Use the config to change settings.
  Comment out a config definition to disable that feature.

*/

#include "xobj_core/_ROOT.lsl"

/*
  CONFIG
*/
// Max range for owner
#define OWNER_RANGE 0
// Max distance from prim to track
#define AGENT_RANGE 64
// Do not track object owner
#define DISREGARD_OWNER

/*
    Global variables
*/
// List of keys of people currently in the sim
list CACHE_PEOPLE;


/*
    Global functions
*/

sendIM(string message){
    
    #ifdef OWNER_RANGE
    if(
        // Owner in region
        llKey2Name(llGetOwner()) != "" && 
        // And close by
        llVecDist(prPos(llGetOwner()), llGetPos())<OWNER_RANGE
    )return;
    #endif
    
    llInstantMessage(llGetOwner(), message);
    
}

// Updates
tick(){
    
    list active = llGetAgentList(AGENT_LIST_PARCEL, []);
    list out;
    list added;
    list removed;
    
    vector gpos = llGetPos();
        
    // Scan add check new and existing
    list_shift_each(CACHE_PEOPLE, id,
    
        integer pos = llListFindList(active, [(key)id]);
        
        // Player leaving the sim
        if(pos == -1){
            removed+= id;
        }
        // Player remaining in the sim
        else
            out+= id;
        
    )
    
    // Check for new arrivals
    while(active){
        
        string id = l2s(active, 0);
        active = llDeleteSubList(active, 0, 0);
        
        integer pos = llListFindList(out, [id]);
        if(
            pos == -1
            #ifdef DISREGARD_OWNER
            && id != (str)llGetOwner()
            #endif
            #ifdef AGENT_RANGE
            && llVecDist(prPos(id), gpos) < AGENT_RANGE
            #endif
        ){
            out+= id;
            added+= id;
        }
        
    }
    
    CACHE_PEOPLE = out;
    
    list names;
    integer i;
    for(i=0; i<count(CACHE_PEOPLE); ++i){
        names += llKey2Name(l2s(CACHE_PEOPLE, i));
    }
    
    llSetText(implode("\n", names), <1,1,1>, 1);
    
    
    // Send IMs
    if(added){
        
        string add = "";
        list_shift_each(added, id,
            add+= "\n - secondlife:///app/agent/"+id+"/about";
        )
        sendIM("/me ~ Entered the sim: "+add);
        
    }
    
    if(removed){
        
        string add = "";
        list_shift_each(removed, id,
            add+= "\n - secondlife:///app/agent/"+id+"/about";
        )
        sendIM("/me ~ Left the sim: "+add);
        
        
    }
    
}

default
{
    
    state_entry(){llSetTimerEvent(4);}
    
    timer(){tick();}
    
}
